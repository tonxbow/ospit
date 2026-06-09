local module=...
local auth={}

function auth.authenticate(user, password, invalidate)
    local match = (auth.disabled() or webkeyhash == password)
    if (invalidate) then
        auth.create_challenge()
    end
    if (module) then
        package.loaded[module]=nil
        module=nil
    end
    return auth.validuser(user) and match
end

function auth.challenge()
    if (randomstring == nil) then
        auth.create_challenge()
    end
    return randomstring
end

function auth.create_challenge()
    if encrypted_webkey == true and webkeyhash ~= nil then
        randomstring = encoder.toHex(sodium.random.buf(16))
        local randomstringforhash = randomstring .. webkey
        local hashobj = crypto.new_hash("SHA256")
        hashobj:update(randomstringforhash)
        local digest = hashobj:finalize()
        webkeyhash = encoder.toHex(digest)

        print("Randomstringforhash:", randomstringforhash)
        print("webkey:", webkey)
        print("Randomstring:", randomstring)
        print("Digest Hex:", webkeyhash)
        print("FreeMEM:", node.heap())

     else
        webkeyhash = webkey
        randomstring = "Encryption not enabled."
     end
end

function auth.disabled()
    return (webkeyhash == nil or webkeyhash == '')
end

function auth.validuser(user)
    return (auth.disabled() or user == 'root' or user == 'lua' )
end

return auth
