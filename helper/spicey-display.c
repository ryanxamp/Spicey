/*
 * spicey-display — minimal SPICE display helper for Spicey.app
 *
 * Reads a Proxmox virt-viewer .vv file and opens a SPICE window.
 * The heavy lifting (protocol, TLS, proxy CONNECT tunnel, image
 * decoding, input handling) is done by spice-gtk. We only translate
 * the .vv key/values into SpiceSession properties and show the widget.
 *
 * Usage:  spicey-display <file.vv> [--fullscreen] [--no-scale]
 *
 * Exit codes:
 *   0  clean disconnect / window closed
 *   2  bad arguments
 *   3  .vv parse error
 *   4  connection error (see stderr)
 */

#include <glib.h>
#include <gtk/gtk.h>
#include <spice-client.h>
#include <spice-client-gtk.h>
#include <string.h>
#include <stdlib.h>

typedef struct {
    GtkWidget    *window;
    SpiceSession *session;
    gboolean      connected;   /* did we ever successfully open a channel? */
    int           exit_code;
} App;

/* Pull a string from the [virt-viewer] group, or NULL if absent/empty.
 * GKeyFile un-escapes the \n sequences Proxmox embeds in the ca= value,
 * which is exactly what we want. Caller frees. */
static gchar *vv_get(GKeyFile *kf, const char *key) {
    gchar *v = g_key_file_get_string(kf, "virt-viewer", key, NULL);
    if (v && *v == '\0') { g_free(v); return NULL; }
    return v;
}

static void on_main_channel_event(SpiceChannel *channel, SpiceChannelEvent event, gpointer data) {
    (void)channel;
    App *app = data;
    switch (event) {
    case SPICE_CHANNEL_OPENED:
        app->connected = TRUE;
        break;
    case SPICE_CHANNEL_CLOSED:
        /* normal shutdown initiated by remote */
        gtk_main_quit();
        break;
    case SPICE_CHANNEL_ERROR_AUTH:
        g_printerr("spicey-display: authentication failed — the SPICE ticket "
                   "in this .vv file has likely expired. Reopen the console "
                   "from the Proxmox web UI to get a fresh file.\n");
        app->exit_code = 4;
        gtk_main_quit();
        break;
    case SPICE_CHANNEL_ERROR_TLS:
        g_printerr("spicey-display: TLS error — certificate verification "
                   "against the embedded CA / host-subject failed.\n");
        app->exit_code = 4;
        gtk_main_quit();
        break;
    case SPICE_CHANNEL_ERROR_CONNECT:
        g_printerr("spicey-display: could not connect. Check the proxy host is "
                   "reachable from this machine.\n");
        app->exit_code = 4;
        gtk_main_quit();
        break;
    case SPICE_CHANNEL_ERROR_LINK:
    case SPICE_CHANNEL_ERROR_IO:
        g_printerr("spicey-display: connection dropped.\n");
        app->exit_code = 4;
        gtk_main_quit();
        break;
    default:
        break;
    }
}

static void on_channel_new(SpiceSession *session, SpiceChannel *channel, gpointer data) {
    (void)session;
    App *app = data;
    if (SPICE_IS_MAIN_CHANNEL(channel)) {
        g_signal_connect(channel, "channel-event",
                         G_CALLBACK(on_main_channel_event), app);
    }
    /* Display channels are picked up automatically by the SpiceDisplay
     * widget we created; nothing to wire up here. */
}

static void on_window_destroy(GtkWidget *w, gpointer data) {
    (void)w; (void)data;
    gtk_main_quit();
}

int main(int argc, char **argv) {
    gtk_init(&argc, &argv);

    const char *vv_path = NULL;
    gboolean fullscreen = FALSE;
    gboolean scale = TRUE;

    for (int i = 1; i < argc; i++) {
        if (g_strcmp0(argv[i], "--fullscreen") == 0)      fullscreen = TRUE;
        else if (g_strcmp0(argv[i], "--no-scale") == 0)   scale = FALSE;
        else if (argv[i][0] != '-' && vv_path == NULL)    vv_path = argv[i];
    }
    if (!vv_path) {
        g_printerr("usage: spicey-display <file.vv> [--fullscreen] [--no-scale]\n");
        return 2;
    }

    GKeyFile *kf = g_key_file_new();
    GError *err = NULL;
    if (!g_key_file_load_from_file(kf, vv_path, G_KEY_FILE_NONE, &err)) {
        g_printerr("spicey-display: cannot read %s: %s\n", vv_path,
                   err ? err->message : "unknown error");
        return 3;
    }
    if (!g_key_file_has_group(kf, "virt-viewer")) {
        g_printerr("spicey-display: %s is missing the [virt-viewer] section\n", vv_path);
        return 3;
    }

    gchar *type        = vv_get(kf, "type");
    if (type && g_ascii_strcasecmp(type, "spice") != 0) {
        g_printerr("spicey-display: unsupported type '%s' (only spice)\n", type);
        return 3;
    }

    gchar *host        = vv_get(kf, "host");
    gchar *port        = vv_get(kf, "port");
    gchar *tls_port    = vv_get(kf, "tls-port");
    gchar *password    = vv_get(kf, "password");
    gchar *proxy       = vv_get(kf, "proxy");
    gchar *ca          = vv_get(kf, "ca");
    gchar *subject     = vv_get(kf, "host-subject");
    gchar *title       = vv_get(kf, "title");

    if (!host || (!port && !tls_port)) {
        g_printerr("spicey-display: .vv is missing host / port information\n");
        return 3;
    }

    App app = { 0 };
    app.exit_code = 0;
    app.session = spice_session_new();

    g_object_set(app.session, "host", host, NULL);
    if (port)     g_object_set(app.session, "port", port, NULL);
    if (tls_port) g_object_set(app.session, "tls-port", tls_port, NULL);
    if (password) g_object_set(app.session, "password", password, NULL);
    if (proxy)    g_object_set(app.session, "proxy", proxy, NULL);

    if (ca) {
        /* mirror virt-viewer: pass the PEM bytes incl. trailing NUL */
        GByteArray *ca_bytes = g_byte_array_new();
        g_byte_array_append(ca_bytes, (const guint8 *)ca, strlen(ca) + 1);
        g_object_set(app.session, "ca", ca_bytes, NULL);
        g_byte_array_unref(ca_bytes);
    }
    if (subject) {
        /* Proxmox connects through a proxy to a synthetic hostname, so we
         * verify the certificate by SUBJECT (not hostname). */
        g_object_set(app.session,
                     "cert-subject", subject,
                     "verify", SPICE_SESSION_VERIFY_SUBJECT,
                     NULL);
    }

    g_signal_connect(app.session, "channel-new",
                     G_CALLBACK(on_channel_new), &app);

    /* Window + display widget */
    app.window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(app.window), title ? title : "Spicey");
    gtk_window_set_default_size(GTK_WINDOW(app.window), 1024, 768);
    g_signal_connect(app.window, "destroy", G_CALLBACK(on_window_destroy), &app);

    GtkWidget *display = GTK_WIDGET(spice_display_new(app.session, 0));
    g_object_set(display,
                 "scaling", scale,
                 "resize-guest", FALSE,
                 NULL);
    gtk_container_add(GTK_CONTAINER(app.window), display);

    gtk_widget_show_all(app.window);
    if (fullscreen) gtk_window_fullscreen(GTK_WINDOW(app.window));

    if (!spice_session_connect(app.session)) {
        g_printerr("spicey-display: spice_session_connect() failed to start\n");
        return 4;
    }

    gtk_main();

    spice_session_disconnect(app.session);
    g_object_unref(app.session);
    g_key_file_free(kf);
    return app.exit_code;
}
