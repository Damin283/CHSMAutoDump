local a=game:GetService("Players")
local b=a.LocalPlayer
local c="https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"
local d=4
local e=4.5
local f=4.7
local g=5
local h=3
local i=3
local j=false
local k=false
local l=false
local m=0
local n=0
local o={
{name="1",waypoints={Vector3.new(59.3844,726.2589,-553.9585)},waitTime=e},
{name="2",waypoints={
Vector3.new(-49.812450134277344,726.3965454101562,-548.9459838867188),
Vector3.new(-60.85980224609375,726.3966064453125,-775.8695678710938),
Vector3.new(-128.3144073486328,726.6795654296875,-762.6356201171875),
Vector3.new(-127.90377044677734,726.6796264648438,-623.9077758789062)
},returnWaypoints={
Vector3.new(-127.90377044677734,726.6796264648438,-623.9077758789062),
Vector3.new(-128.3144073486328,726.6795654296875,-762.6356201171875),
Vector3.new(-60.85980224609375,726.3966064453125,-775.8695678710938)
},waitTime=f},
{name="3",waypoints={
Vector3.new(359.06683349609375,709.7947998046875,-772.297607421875),
Vector3.new(342.5182189941406,710.3426513671875,-900.2728271484375)
},waitTime=e},
{name="4",waypoints={
Vector3.new(747.9673461914062,710.4390258789062,-889.592041015625),
Vector3.new(917.7178955078125,709.6536865234375,-760.108154296875),
Vector3.new(1090.612060546875,710.4390258789062,-815.144287109375)
},waitTime=e},
{name="5",waypoints={
Vector3.new(1073.725830078125,719.2354736328125,-712.980224609375),
Vector3.new(1044.5260009765625,710.4390258789062,-610.3722534179688)
},waitTime=e},
{name="6",waypoints={
Vector3.new(1109.643310546875,709.6878662109375,-366.28631591796875),
Vector3.new(1036.7313232421875,711.1288452148438,-136.04592895507812)
},waitTime=e},
{name="7",waypoints={
Vector3.new(1144.709716796875,709.6878662109375,5.922271184921265),
Vector3.new(1149.110107421875,709.6878662109375,207.83314514160156),
Vector3.new(749.5130615234375,710.841796875,206.46275329589844),
Vector3.new(750.3395385742188,710.841796875,345.1310119628906)
},waitTime=e}
}
local p=Vector3.new(91.52301025390625,726.2588850097656,-625.6691284179688)
local q,r=pcall(function()return loadstring(game:HttpGet(c))()end)
if not q or type(r)~="table" then warn("[D] lib fail") return end
local s=r:CreateWindow({Title="Dumpster Utility Pro | v1.4.0",Center=true,AutoShow=true})
local t=s:AddTab("Main")
local u=s:AddTab("Log")
local v=t:AddLeftGroupbox("Auto")
local w=t:AddRightGroupbox("Status")
local x=u:AddLeftGroupbox("History")
local y=w:AddLabel("ready")
local function z(A)
print("[D]",A)
if not k then pcall(function()y:SetText(A)end) end
end
x:AddLabel("v1.4.0 path + return")
x:AddLabel("2=4.7s others=4.5s npc=4s")
x:AddLabel(" ")
x:AddLabel("v1.3.3 move check")
x:AddLabel("v1.3.2 ui fix")
x:AddLabel("v1.3.1 small fix")
local function aa()
local ab=b.Character
return ab and ab:FindFirstChild("HumanoidRootPart")
end
local function ac(ad)
if not j or k then return false end
for ae=1,i do
if not j or k then return false end
local af=aa()
if not af then z("no char") return false end
af.CFrame=CFrame.new(ad)
local ag=os.clock()+h
repeat
if not j or k then return false end
af=aa()
if not af then break end
if (af.Position-ad).Magnitude<=g then return true end
task.wait(0.1)
until os.clock()>=ag
if ae<i then z(("retry %d/%d"):format(ae,i)) task.wait(0.25) end
end
z("move fail stop")
return false
end
local function ah(ai,aj)
if not ai or #ai==0 then return false end
for ak,al in ipairs(ai) do
if not j or k then return false end
z(("%s %d/%d"):format(aj,ak,#ai))
if not ac(al) then return false end
end
return true
end
local function am(an)
local ao=os.clock()+an
while os.clock()<ao do
if not j or k then return false end
task.wait(0.05)
end
return j and not k
end
local function ap()
if l or k then return end
l=true
while j and not k do
z("to npc")
if not ac(p) then break end
z(("npc wait %.1f"):format(d))
if not am(d) then break end
local aq=false
for ar,as in ipairs(o) do
if not j or k then aq=true break end
m=ar
if not ah(as.waypoints,as.name.." in") then aq=true break end
local at=as.waitTime or e
z(("%s wait %.1f"):format(as.name,at))
if not am(at) then aq=true break end
if as.returnWaypoints then
if not ah(as.returnWaypoints,as.name.." out") then aq=true break end
end
end
if aq or not j or k then break end
z("back npc")
if not ac(p) then break end
n=n+1
m=0
z(("cycle %d done npc wait %.1f"):format(n,d))
if not am(d) then break end
end
l=false
if not k then
if j then j=false z("move fail stopped")
else z(("paused c%d i%d"):format(n,m)) end
end
end
v:AddToggle("AutoRoute",{Text="Auto ON/OFF",Default=false,Callback=function(au)
if k then return end
j=au
if j and not l then task.spawn(ap)
elseif not j then z("paused - turn ON") end
end})
v:AddButton({Text="Check",Func=function()
z(("done %d / now %d/%d"):format(n,m,#o))
end})
v:AddButton({Text="Reset",Func=function()
if k then return end
j=false m=0 n=0
z("reset - turn ON")
end})
v:AddButton({Text="To NPC",Func=function()
if k then return end
if j then z("turn OFF first") return end
local av=aa()
if not av then z("no char") return end
av.CFrame=CFrame.new(p)
z("npc tp done")
end})
v:AddButton({Text="Close UI",Func=function()
if k then return end
j=false k=true
pcall(function()r:Unload()end)
end})
r:Notify("Dumpster Utility Pro v1.4.0 loaded",4)
z("ready - turn ON")
