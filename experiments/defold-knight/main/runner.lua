-- Engine-independent runner simulation. Units are seconds, metres and lane widths.
local M = {}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function random(s,n)
    s.seed = (s.seed * 48271) % 2147483647
    return s.seed % n
end
function M.new()
    return { mode="ready", seed=381, lane=0, x=0, vx=0, height=0, vy=0,
        speed=10, distance=0, coins=0, hp=3, time=0, phase=0, slide=0,
        crouch=0, land=0, attack=0, hurt=0, invulnerable=0, jump_buffer=0,
        row=0, next_row=43, objects={}, events={}, jumps=0, hits=0,
        dodges=0, slides=0, attacks=0, elapsed=0, input_count=0 }
end
local function emit(s,name) s.events[#s.events+1]=name end
function M.command(s,command)
    if command=="restart" then
        local fresh=M.new()
        for key,value in pairs(fresh) do s[key]=value end
        s.mode="running"
        return
    end
    if command=="pause" then
        if s.mode=="running" then s.mode="paused"
        elseif s.mode=="paused" then s.mode="running" end
        return
    end
    if command=="resume" and s.mode=="paused" then s.mode="running";return end
    if command=="start" and s.mode=="ready" then s.mode="running";return end
    if s.mode~="running" then return end
    s.input_count=s.input_count+1
    if command=="left" then s.lane=clamp(s.lane-1,-1,1);s.dodges=s.dodges+1
    elseif command=="right" then s.lane=clamp(s.lane+1,-1,1);s.dodges=s.dodges+1
    elseif command=="jump" then s.jump_buffer=.15
    elseif command=="slide" and s.height<.08 then
        s.slide=.72;s.slides=s.slides+1;emit(s,"slide")
    elseif command=="attack" and s.attack==0 then
        s.attack=.42;s.attacks=s.attacks+1;emit(s,"attack")
    end
end
local function row(s)
    s.row=s.row+1
    local lane,kind
    -- Three readable teaching encounters, followed by deterministic variation.
    if s.row==1 then lane=0;kind="hurdle"
    elseif s.row==2 then lane=0;kind="arch"
    elseif s.row==3 then lane=0;kind="ward"
    else
        lane=random(s,3)-1
        kind=({"hurdle","arch","ward"})[random(s,3)+1]
    end
    s.objects[#s.objects+1]={z=s.next_row,lane=lane,kind=kind,done=false}
    local safe=(lane+1)%3-1
    if safe==lane then safe=(lane==1 and 0 or 1) end
    for i=1,4 do
        s.objects[#s.objects+1]={z=s.next_row-6-i*2.7,lane=safe,kind="coin",done=false}
    end
    s.next_row=s.next_row+27+random(s,5)
end
function M.step(s,dt)
    s.events={}
    if s.mode~="running" then return end
    -- Substep integration is performed here, not left to the browser's frame rate.
    local remaining=math.min(dt,.25)
    while remaining>0 do
        local h=math.min(remaining,1/120)
        remaining=remaining-h
        s.time=s.time+h;s.elapsed=s.elapsed+h
        s.speed=math.min(15,10+s.distance*.002)
        local previous=s.distance
        s.distance=s.distance+s.speed*h
        s.phase=(s.phase+h*(2.25+s.speed*.015)*math.pi*2)%(math.pi*2)
        -- Critically damped lane response, bounded and independent of update rate.
        local omega=20
        local offset=s.x-s.lane
        local c=s.vx+omega*offset
        local decay=math.exp(-omega*h)
        s.x=s.lane+(offset+c*h)*decay
        s.vx=(s.vx-omega*c*h)*decay
        if s.jump_buffer>0 and s.height==0 and s.slide==0 then
            s.vy=8.7;s.jumps=s.jumps+1;s.jump_buffer=0;emit(s,"jump")
        end
        s.jump_buffer=math.max(0,s.jump_buffer-h)
        if s.height>0 or s.vy>0 then
            s.height=math.max(0,s.height+s.vy*h-11*h*h)
            s.vy=s.vy-22*h
            if s.height==0 and s.vy<0 then
                s.vy=0;s.land=.20;emit(s,"land")
            end
        end
        s.slide=math.max(0,s.slide-h)
        local target=s.slide>0 and 1 or 0
        s.crouch=s.crouch+(target-s.crouch)*(1-math.exp(-22*h))
        s.land=math.max(0,s.land-h)
        s.attack=math.max(0,s.attack-h)
        s.hurt=math.max(0,s.hurt-h)
        s.invulnerable=math.max(0,s.invulnerable-h)
        while s.next_row<s.distance+140 do row(s) end
        for _,o in ipairs(s.objects) do
            if not o.done and o.z<=s.distance and o.z>previous then
                o.done=true
                if math.abs(s.x-o.lane)<.37 then
                    if o.kind=="coin" then
                        s.coins=s.coins+1;emit(s,"coin")
                    else
                        local avoided=(o.kind=="hurdle" and s.height>.8)
                            or (o.kind=="arch" and s.slide>0)
                            or (o.kind=="ward" and s.attack>.04)
                        if avoided then emit(s,"clear")
                        elseif s.invulnerable==0 then
                            s.hp=s.hp-1;s.hurt=.38;s.invulnerable=1.25
                            s.hits=s.hits+1;emit(s,"damage")
                            if s.hp==0 then s.mode="defeat";emit(s,"defeat") end
                        end
                    end
                end
            end
        end
        for i=#s.objects,1,-1 do
            if s.objects[i].z<s.distance-12 then table.remove(s.objects,i) end
        end
        if s.mode=="defeat" then break end
    end
end
return M
