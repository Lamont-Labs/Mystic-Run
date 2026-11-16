-- Painted concept pixels, independently transformed joints; no static pose crossfade.
local data=require("art.rig")
local M={}
local function rotate(x,y,r)
    local c,s=math.cos(r),math.sin(r)
    return x*c-y*s,x*s+y*c
end
function M.new()
    local actor={nodes={},data={}}
    local ordered={}
    for _,p in ipairs(data.parts) do ordered[#ordered+1]=p;actor.data[p.name]=p end
    table.sort(ordered,function(a,b) return a.z<b.z end)
    for _,p in ipairs(ordered) do
        local node=gui.new_box_node(vmath.vector3(),vmath.vector3(1,1,0))
        gui.set_layer(node,"hero");gui.set_texture(node,"art")
        gui.play_flipbook(node,"p_"..p.name)
        gui.set_size_mode(node,gui.SIZE_MODE_MANUAL)
        gui.set_size(node,vmath.vector3(p.region[3],p.region[4],0))
        actor.nodes[p.name]=node
    end
    return actor
end
function M.update(actor,s,x,feet)
    local moving=s.mode=="running" or s.mode=="paused"
    local phase=s.phase
    local strength=moving and 1 or .08
    local crouch=s.crouch
    local bob=(1-math.cos(phase*2))*2.8*strength
    local lean=-s.vx*.009
    local impact=math.sin((s.land/.20)*math.pi)*4
    local attack=s.attack>0 and math.sin(s.attack/.42*math.pi) or 0
    local angles={
        pelvis=lean*.25,
        torso=math.sin(phase)*.025*strength+lean+crouch*.12-attack*.1,
        head=-lean*.5-math.sin(phase)*.018*strength,
        cape=math.sin(phase-.8)*.045*strength+math.sin(s.time*11)*.022,
        shield=math.sin(phase)*.10*strength-crouch*.12,
        upperarm_r=-math.sin(phase)*.19*strength-attack*.8,
        forearm_r=.08+math.sin(phase+.8)*.11*strength-attack*.48,
        sword=math.sin(phase-.3)*.055-attack*.22
    }
    if s.height>0 then
        angles.cape=angles.cape-.08;angles.shield=-.12
        angles.upperarm_r=.20;angles.forearm_r=-.18
    end
    if s.hurt>0 then angles.torso=angles.torso+math.sin(s.hurt*24)*.10 end
    local world={}
    world.pelvis={x=142,y=219+bob+impact+18*crouch,r=angles.pelvis,sy=1}
    local function segment(name,ax,ay,bx,by,restx,resty)
        local p=actor.data[name]
        local dx,dy=bx-ax,by-ay
        world[name]={x=ax,y=ay,
            r=math.atan2(dy,dx)-math.atan2(resty,restx),
            sy=math.sqrt(dx*dx+dy*dy)/math.sqrt(restx*restx+resty*resty)}
    end
    for side=0,1 do
        local suffix=side==0 and "_l" or "_r"
        local hipx=side==0 and 108 or 169
        local kneex=side==0 and 95 or 185
        local anklex=side==0 and 77 or 195
        local ankley=side==0 and 326 or 327
        local t=(phase/(2*math.pi)+side*.5)%1
        local footy,lift
        if t<.58 then
            footy=-13+26*(t/.58);lift=0
        else
            local u=(t-.58)/.42
            lift=math.sin(u*math.pi)*43
            footy=13-26*u-lift
        end
        if s.height>0 then footy=-22;lift=28 end
        footy=footy*strength
        local hy=222+bob+impact+20*crouch
        local ky=266-lift*.46*strength+29*crouch+impact*.3
        local ay=ankley+footy
        segment("thigh"..suffix,hipx,hy,kneex,ky,kneex-hipx,44)
        segment("shin"..suffix,kneex,ky,anklex,ay,anklex-kneex,ankley-266)
        world["boot"..suffix]={x=anklex,y=ay,r=-footy*.0025,sy=1}
    end
    for _,p in ipairs(data.parts) do
        if not world[p.name] then
            local parent=world[p.parent]
            local original=actor.data[p.parent].joint
            local dx,dy=rotate(p.joint[1]-original[1],p.joint[2]-original[2],parent.r)
            world[p.name]={x=parent.x+dx,y=parent.y+dy,
                r=parent.r+(angles[p.name] or 0),sy=1}
        end
        local pose=world[p.name]
        local cx=(p.source_rect[1]+p.source_rect[3])/2-p.joint[1]
        local cy=(p.source_rect[2]+p.source_rect[4])/2-p.joint[2]
        local dx,dy=rotate(cx,cy*pose.sy,pose.r)
        local scale=.70
        local squash=1-.25*crouch
        gui.set_position(actor.nodes[p.name],vmath.vector3(
            x+(pose.x+dx-142)*scale,
            feet+(352-pose.y-dy)*scale*squash,0))
        gui.set_scale(actor.nodes[p.name],vmath.vector3(scale,scale*pose.sy*squash,1))
        gui.set_euler(actor.nodes[p.name],vmath.vector3(0,0,-pose.r*180/math.pi))
        local tint=s.invulnerable>0 and (.70+.30*math.abs(math.sin(s.time*20))) or 1
        gui.set_color(actor.nodes[p.name],vmath.vector4(1,tint,tint,1))
    end
end
return M
