vcl 4.1;

acl admin_network {
	"localhost";
	"157.245.40.168";
	"ADMIN_IP";
}

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "159.65.217.139";
    .port = "80";
}

sub vcl_recv {
    if (req.url == "/admin") {
        if (!client.ip ~ admin_network) {
            return (synth(403, "Access Denied"));
        }
        return (synth(200, "Admin Access Granted"));
    }

    # let coding files pass through
    if (req.url ~ "\.(css|js|png|jpg)$") {
        return (hash);
    }

    # 3. Block everything else
    if (req.url != "/") {
         return (synth(404, "Not Found"));
    }
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
    if (obj.hits > 0) {
	set resp.http.X-Cache = "HIT";
    } else {
	set resp.http.X-Cache = "MISS";
    }
    set resp.http.X-Powered-By = "Zinger's Varnish CDN";
}


sub vcl_synth {
	if (resp.status == 404) {
        set resp.http.Content-Type = "text/html; charset=utf-8";
        synthetic({"
            <!DOCTYPE html>
            <html>
            <head>
                <title>404 Not Found</title>
                <script src="https://cdn.tailwindcss.com"></script>
            </head>
            <body class="bg-slate-900 text-white h-screen flex flex-col items-center justify-center font-sans">
                <div class="text-center p-8 bg-slate-800 rounded-xl border border-slate-700 shadow-2xl">
                    <h1 class="text-6xl font-bold text-red-500 mb-4">404</h1>
                    <h2 class="text-2xl font-semibold mb-2">Page Not Found</h2>
                    <p class="text-slate-400 mb-6">The page you are looking for does not exist on this Edge Node.</p>
                    <a href="/" class="px-6 py-2 bg-blue-600 hover:bg-blue-500 rounded-lg font-medium transition">
                        Go Home
                    </a>
                </div>
                <p class="mt-8 text-xs text-slate-600 font-mono">FlashPoint CDN • London Edge</p>
            </body>
            </html>
        "});
        
        return (deliver);
    	}
        if (resp.status == 403) {
                set resp.http.Content-Type = "text/html; charset=utf-8";
		synthetic("<html><body><h1>403 ERROR, You cannot access this page as you are not an admin</h1></body></html>");
                return (deliver);
	}
	if (resp.status == 200) {
		set resp.http.Content-Type = "text/html; charset=utf-8";
		synthetic("<html><body><h1> Access Granted, you are an admin </h1></body></html>");
		return (deliver);
	}
}
