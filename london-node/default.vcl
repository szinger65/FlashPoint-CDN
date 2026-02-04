vcl 4.1;
import std; # Standard library for string manipulation and logging

#ACL
acl admin_network {
    "localhost";
    "127.0.0.1";
    "ADMIN_IP"; # Replace with your real IP
}

acl purge_allowed {
    "localhost";
    "127.0.0.1";
}

backend default {
    .host = "159.65.217.139";
    .port = "80";
    # Advanced Health Probe
    # If the backend takes >1s to reply, serve stale cache
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}

sub vcl_recv {

    if (req.http.User-Agent ~ "(?i)(sqlmap|nikto|curl|python-requests|go-http-client)") {
        return (synth(403, "Bot Detected"));
    }

    if (req.method != "GET" && req.method != "HEAD" && req.method != "PURGE" && req.method != "OPTIONS") {
        return (synth(405, "Method Not Allowed"));
    }

    if (req.method == "PURGE") {
        if (!client.ip ~ purge_allowed) {
            return (synth(405, "IP Not Allowed to Purge"));
        }
        return (purge);
    }

    if (req.url ~ "/$") {
        set req.url = regsub(req.url, "/$", "");
        return (synth(301, "Moved Permanently"));
    }

    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|gclid|fbclid)=") {
        set req.url = regsuball(req.url, "(\?|&)(utm_source|utm_medium|utm_campaign|gclid|fbclid)=[^&]+", "");
        set req.url = regsub(req.url, "(\?&)", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    #Image support within the browser
    if (req.http.Accept ~ "image/webp") {
        set req.http.X-WebP-Support = "true";
    }

    if (req.method == "OPTIONS") {
        return (synth(204, "CORS OK"));
    }

    #Using ACL for admin routing
    if (req.url == "/admin") {
        if (!client.ip ~ admin_network) {
            return (synth(403, "Access Denied"));
        }
        return (synth(200, "Admin OK"));
    }

    if (req.url == "/health") {
        return (synth(200, "Health OK"));
    }

    if (req.url ~ "\.(css|js|png|jpg|jpeg|svg|ico)$") {
        unset req.http.Cookie; # Strip cookies to enforce caching
        return (hash);
    }

	#Fallback
    if (req.url != "/") {
        return (synth(404, "Not Found"));
    }
}

#Backend Responses
sub vcl_backend_response {
    
    # A. Content Optimization
    # If the client supports WebP, tell the backend via Vary header
    if (bereq.http.X-WebP-Support == "true") {
        set beresp.http.Vary = "Accept";
    }

    #Force Long Cache for Static Assets
    if (bereq.url ~ "\.(css|js|png|jpg)$") {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 1d; 
    }

    # If backend is dead, keep serving old content for 6 hours
    set beresp.grace = 6h;
}

#Response Processing
sub vcl_deliver {
    
    #Security Headers (HSTS, XSS Protection)
    set resp.http.X-Frame-Options = "DENY";
    set resp.http.X-Content-Type-Options = "nosniff";
    set resp.http.Strict-Transport-Security = "max-age=31536000; includeSubDomains";
    
    #CORS Headers
    set resp.http.Access-Control-Allow-Origin = "*";

    #Observability Headers
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }
    
    set resp.http.X-Powered-By = "FlashPoint CDN (Varnish)";
    unset resp.http.Server;
    unset resp.http.Via;
    unset resp.http.X-Varnish;
}

#Vcl Synthetic Responses
sub vcl_synth {
    
    # Handle Redirects (301)
    if (resp.status == 301) {
        set resp.http.Location = req.url;
        return (deliver);
    }

    # Handle CORS Preflight (204)
    if (resp.status == 204) {
        set resp.http.Access-Control-Allow-Origin = "*";
        set resp.http.Access-Control-Allow-Methods = "GET, POST, OPTIONS";
        set resp.http.Access-Control-Max-Age = "86400";
        return (deliver);
    }

    # Handle Health Check (JSON)
    if (req.url == "/health") {
        set resp.http.Content-Type = "application/json";
        synthetic({"{"status": "UP", "region": "EU-London"}"});
        return (deliver);
    }

    # Standard HTML Errors
    set resp.http.Content-Type = "text/html; charset=utf-8";

    if (resp.status == 200) {
        synthetic("<h1>Admin Access Granted</h1>");
        return (deliver);
    }
    if (resp.status == 403) {
        synthetic("<h1>403 Forbidden: Bot or Unauthorized IP</h1>");
        return (deliver);
    }
    if (resp.status == 404) {
        synthetic("<h1>404 Not Found</h1>");
        return (deliver);
    }
}
