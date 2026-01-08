vcl 4.1;

acl admin_network {
	"localhost";
	"157.245.40.168";
	"88.185.247.79";
}

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "159.65.217.139";
    .port = "80";
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.
    if (req.url == "/admin") {
    	if (!client.ip ~ admin_network) {
		return (synth(403, "Access Denied"));
        }
	return (synth(200, "Admin Access Granted"));
    }
    if (req.url != "/" && req.url != "/admin") {
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
		synthetic("<html><body><h1>404 ERROR, Error finding page, please try again with a different page</h1></body></html>");
		return (deliver);
	}
        if (resp.status == 403) {
                set resp.http.Content-Type = "test/html; charset=utf-8";
		synthetic("<html><body><h1>403 ERROR, You cannot access this page as you are not an admin</h1></body></html>");
                return (deliver);
	}
	if (resp.status == 200) {
		set resp.http.Content-Type = "text/html; charset=utf-8";
		synthetic("<html><body><h1> Access Granted, you are an admin </h1></body></html>");
		return (deliver);
	}
}
