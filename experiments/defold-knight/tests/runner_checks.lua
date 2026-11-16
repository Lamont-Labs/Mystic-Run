local runner=require("main.runner")
local M={}
function M.run()
    local count=0
    local function check(value,message) assert(value,message);count=count+1 end
    local function advance(s,seconds,h)
        for _=1,math.floor(seconds/h+.5) do runner.step(s,h) end
    end
    local s=runner.new()
    runner.step(s,1/60);check(s.distance==0,"ready must not advance")
    runner.command(s,"start");runner.command(s,"right")
    advance(s,.3,1/120)
    check(s.x>.98 and s.x<=1,"lane convergence or overshoot")
    runner.command(s,"right");check(s.lane==1,"lane bound")
    runner.command(s,"left");runner.command(s,"left")
    advance(s,.35,1/120)
    check(s.x<-.98,"rapid lane reversal")
    local before=s.distance
    runner.command(s,"pause");advance(s,1,1/60)
    check(s.distance==before,"paused simulation changed")
    runner.command(s,"resume");runner.command(s,"jump")
    advance(s,.2,1/120);check(s.height>1,"jump height")
    advance(s,.65,1/120);check(s.height==0 and s.vy==0,"landing recovery")
    runner.command(s,"slide");advance(s,.05,1/120)
    check(s.slide>0 and s.crouch>.5,"slide response")
    advance(s,1,1/120);check(s.slide==0 and s.crouch<.001,"slide recovery")
    local a,b=runner.new(),runner.new()
    runner.command(a,"start");runner.command(b,"start")
    runner.command(a,"left");runner.command(b,"left")
    advance(a,2,1/30);advance(b,2,1/120)
    check(math.abs(a.distance-b.distance)<.001,"frame-rate-dependent distance")
    check(math.abs(a.x-b.x)<.001,"frame-rate-dependent lanes")
    check(#a.objects==#b.objects,"nondeterministic row generation")
    local c=runner.new();runner.command(c,"start")
    advance(c,4.8,1/120);check(c.hp==2,"unavoided obstacle should damage once")
    runner.command(c,"restart")
    check(c.hp==3 and c.distance==0 and c.coins==0,"restart did not reset trial")
    runner.command(c,"jump");advance(c,.70,1/120)
    runner.command(c,"jump");advance(c,.14,1/120)
    check(c.jumps==2,"pre-landing jump buffer did not fire")
    local d=runner.new();runner.command(d,"start")
    while d.distance<40.8 do runner.step(d,1/120) end
    runner.command(d,"jump")
    while d.distance<44 do runner.step(d,1/120) end
    check(d.hp==3,"jump did not clear first hurdle")
    print("DEFOLD_KNIGHT_CHECKS_PASSED",count)
    return count
end
return M
