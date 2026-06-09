return function(ctx)

    if not ctx:authenticated() then return end

    -- Handle browser sync POST
    if ctx.headers.method == "POST" then
        
        local epoch = tonumber(ctx.postdata.epoch)
        local tz = tonumber(ctx.postdata.tz)

        if epoch then
            time.set(epoch)
        end

        if tz then
            time.settimezone(tz)
        end
    end

    -- Read current time
    local epoch = time.get()
    local valid = epoch and epoch > 1600000000

    local timestr = "TIME NOT SET"

    if valid then
        local t = time.getlocal()
        timestr = string.format(
            "%04d-%02d-%02d %02d:%02d:%02d",
            t.year, t.mon, t.day,
            t.hour, t.min, t.sec
        )
    end

    -- Send HTML
    ctx:send(ctx.http_preamble)
    ctx:send([[
<html>
<head>
<title>System Time</title>

<style>
body { font-family: Arial; text-align:center; margin-top:40px; }
button { font-size:18px; padding:12px 24px; }
.warn { color:red; font-size:20px; font-weight:bold; }
.ok { color:green; font-size:18px; }
</style>
<script>
function syncTime() {

    var now = new Date();

    var epoch = Math.floor(now.getTime() / 1000);

    // JS offset is minutes WEST of UTC → convert to seconds EAST
    var tz = -now.getTimezoneOffset() * 60;

    var xhr = new XMLHttpRequest();
    xhr.open("POST", "", true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.send("epoch=" + epoch + "&tz=" + tz);

    setTimeout(function(){ location.reload(); }, 800);
}
</script>

</head>
<h3><a href=/index>Status page</a> | <a href=/control>System control</a></h3>
<body>
]])

    if valid then
        ctx:send('<div class="ok">Current Device Time:</div>')
        ctx:send('<h2>' .. timestr .. '</h2>')
        ctx:send('<br>')
        ctx:send('<button onclick="syncTime()">Resync from Phone</button>')
    else
        ctx:send('<div class="warn">SYSTEM TIME NOT SET</div>')
        ctx:send('<p>Please sync time from your phone.</p>')
        ctx:send('<br>')
        ctx:send('<button onclick="syncTime()">SYNC TIME NOW</button>')
    end

    ctx:send([[
</body>
</html>
]])
end
