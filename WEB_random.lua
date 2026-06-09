return function(conn)
    send_response(require('auth').challenge())
end
