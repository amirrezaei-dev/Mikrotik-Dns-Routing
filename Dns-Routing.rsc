
:global fileName "domains.txt" ; # File containing domains
:global commentTag "auto-dns-route" ; # Comment for routes
:global gateway "YOUR_GATEWAY" ; # Gateway for routes
:global useResolveAll false ;
:global domains [:toarray ""] 

:if ([:len [/file find name=$fileName]] > 0) do={
    :local content [/file get $fileName contents]
    :local p 0
    :local n [:len $content]
    :while ($p < $n) do={
        :local e [:find $content "\n" $p]
        :if ($e = nil) do={ :set e $n }
        :local line [:pick $content $p $e]
        :if ([:len $line] > 0 && [:pick $line ([:len $line]-1) [:len $line]] = "\r") do={ :set line [:pick $line 0 ([:len $line]-1)] }
        :set line [:trim $line]
        :if ([:len $line] > 0 && [:pick $line 0 1] != "#") do={ :set domains ( $domains , $line ) }
        :set p ($e + 1)
    }
} else={
    :set domains ("example.com","api.example.net") #write your who url to need
}


/ip route remove [find comment~"$commentTag"]


:local added 0
:foreach d in=$domains do={
    :local domain $d
    :local ip ""

    :do {
        :set ip [:resolve $domain]
    } on-error={
        :log warning ("[dns-route] could not resolve " . $domain)
        :set ip ""
    }

    :if ([:len $ip] = 0) do={
        :log warning ("[dns-route] skipping (no IP): " . $domain)
        :continue
    }

    
    :do {
        /ip route add dst-address=($ip . "/32") gateway=$gateway routing-table=main comment=($commentTag . " (" . $domain . ")")
        :set added ($added + 1)
        :log info ("[dns-route] added route " . $ip . " -> " . $gateway . " from " . $domain)
    } on-error={
        :log warning ("[dns-route] failed to add route for " . $ip)
    }
}

:log info ("[dns-route] finished. total_routes_added=" . $added)





