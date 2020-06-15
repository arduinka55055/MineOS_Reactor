local imageL = require("Image")
local GUI = require("GUI")
local system = require("System")
local component = require("component")
local filesystem = require("Filesystem")
local event = require("Event")
local number = require("Number")
local internet = require("Internet")
local keyboard = require("Keyboard")
local unicode = require("Unicode")
--local indus = require("INDUS_STYLE")

local reactor = component.get("reactor")
local turbine = component.get("turbine")

reactor.setActive(false)
turbine.setActive(false)
----------------------------------------------
local tIprev=0
local tErrprev=0-- ID letters from PID regulator
local rIprev=0
local rErrprev=0
-----------
local mainhandler
-----------------------
local Tp=10  
local Ti=0.2 -- PID регулятор турбинка
local Td=3   -- PID regulator turbine
-----------------------
local Rp=0.35
local Ri=0.03 -- PID регулятор реактор
local Rd=0.08 -- PID regulator reactor
--------------------------------------------------------------------------------------------
function n2s(mynumber) -- remove .0 from numbers
    return string.format("%u", number.roundToDecimalPlaces(mynumber));
end

if not filesystem.exists(filesystem.path(system.getCurrentScript()).."reactor.pic") then
    filelist = {'atom.pic', 'coil.pic', 'eff.pic', 'flow.pic', 'fuel.pic','heat.pic','kettle.pic','minus.pic','out.pic','plus.pic','reactor.pic','rf.pic','rod.pic','rpm.pic','ventg.pic','ventr.pic','venty.pic','xrod.pic'}
    for i, myfile in ipairs(filelist) do
        internet.download("https://raw.githubusercontent.com/arduinka55055/MineOS_Reactor/master/Resources/"..myfile, system.getCurrentScript().."Resources/"..myfile)
    end
    
end

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 120, 40, 0xF0F0F0))
local layout = window:addChild(GUI.layout(1, 3, window.width, window.height - 1, 1, 1))

----------------------------------------------
if require("computer").totalMemory()>2000000 then--Picture
local imageReactor=imageL.load(filesystem.path(system.getCurrentScript()).."Resources/reactor.pic")
layout:addChild(GUI.image(0, 0, imageReactor))
end

local enableReactorr=window:addChild(GUI.switchAndLabel(2, 21, 18, 8, 0x66DB80, 0x5D5D5D, 0xEEEEEE, 0xFF0000, "Start",reactor.getActive()))
enableReactorr.switch.eventHandler=function(bullshit1, bullshit2, e1, ...)
    if e1 == "touch" then
        enableReactorr.switch.state = not reactor.getActive()
        reactor.setActive(enableReactorr.switch.state)
		enableReactorr.switch:addAnimation(
			function(animation)
				if enableReactorr.switch.state then
					enableReactorr.switch.pipePosition = number.round(1 + animation.position * (enableReactorr.switch.width - 2))
				else	
					enableReactorr.switch.pipePosition = number.round(1 + (1 - animation.position) * (enableReactorr.switch.width - 2))
				end
			end
		):start(enableReactorr.switch.animationDuration)
	end
end

--  хахаха
local enablePIDr=window:addChild(GUI.switchAndLabel(25, 21, 20, 8, 0x66DB80, 0x5D5D5D, 0xEEEEEE, 0xFF0000, "Manual", false))
enablePIDr.switch.onStateChanged = function()
    if enablePIDr.switch.state then
        enablePIDr.label.text="Auto PID"
        reactor.setActive(true)
        rIprev=0
        rErrprev=0
    else
        enablePIDr.label.text="Manual"
    end
end

local reactorTemperatureS = window:addChild(GUI.slider(6, 23, 40, 0xBBBB00, 0x0, 0xFFFFFF, 0xFF0000, 500, 2000, 1000, true, "Жара: ", " °C"))
reactorTemperatureS.roundValues = true
---------------------------------------------- REACTOR DASHBOARD ИНФО РЕАКТОРА
window:addChild(GUI.image(4, 26, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/heat.pic")))
local reactorTemperature=window:addChild(GUI.text(9, 27, 0xAAAA00, "Temperature"))

window:addChild(GUI.image(4, 28, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/out.pic")))
local reactorOut=window:addChild(GUI.text(9, 29, 0xAAAA00, "mB/tick"))

window:addChild(GUI.image(4, 30, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/fuel.pic")))
local reactorFuel=window:addChild(GUI.text(9, 31, 0xAAAA00, "mB/tick"))

window:addChild(GUI.image(4, 32, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/atom.pic")))
local reactorEff=window:addChild(GUI.text(9, 33, 0xAAAA00, "%"))
-----------------------
window:addChild(GUI.image(27, 26, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/xrod.pic")))

window:addChild(GUI.image(32, 29, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/rod.pic")))
local reactorRod=window:addChild(GUI.text(37, 30, 0xAAAA00, "%"))

window:addChild(GUI.image(33, 26, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/plus.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        if keyboard.isShiftDown() then
            if keyboard.isAltDown() then
                reactor.setAllControlRodLevels(reactor.getControlRodLevel(0)+1)
            else
                reactor.setAllControlRodLevels(100)
            end
        elseif keyboard.isAltDown() then
            reactor.setAllControlRodLevels(reactor.getControlRodLevel(0)+5)
        else
            reactor.setAllControlRodLevels(reactor.getControlRodLevel(0)+10)
        end
    end
end
window:addChild(GUI.image(33, 32, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/minus.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        if keyboard.isShiftDown() then
            if keyboard.isAltDown() then
                reactor.setAllControlRodLevels(reactor.getControlRodLevel(0)-1)
            else
                reactor.setAllControlRodLevels(0)
            end
        elseif keyboard.isAltDown() then
            reactor.setAllControlRodLevels(reactor.getControlRodLevel(0)-5)
        else
            reactor.setAllControlRodLevels(reactor.getControlRodLevel(0)-10)
        end
    end
end


-------------------------------------------------------------------------------------------- TURBINE ТУРБИНА!
local enableTurbinee=window:addChild(GUI.switchAndLabel(86, 3, 18, 8, 0x00EEEE, 0x1D1D1D, 0xEEEEEE, 0xFF0000, "Start",turbine.getActive()))
enableTurbinee.switch.eventHandler=function(bullshit1, bullshit2, e1, ...)
    if e1 == "touch" then
        enableTurbinee.switch.state = not turbine.getActive()
        turbine.setActive(enableTurbinee.switch.state)
		enableTurbinee.switch:addAnimation(
			function(animation)
				if enableTurbinee.switch.state then
					enableTurbinee.switch.pipePosition = number.round(1 + animation.position * (enableTurbinee.switch.width - 2))
				else	
					enableTurbinee.switch.pipePosition = number.round(1 + (1 - animation.position) * (enableTurbinee.switch.width - 2))
				end
			end
		):start(enableTurbinee.switch.animationDuration)
	end
end


---------------------------------------------- PID REGULATOR(ULTRA NEW AI Technology ©) 
local speedSelector=window:addChild(GUI.switchAndLabel(100, 5, 16, 6, 0x00FFFF, 0x1D1D1D, 0x8A2BE2, 0x8A2BE2, "900 RPM", false))
speedSelector.switch.onStateChanged = function()
    if speedSelector.switch.state then
        speedSelector.label.text="1800 RPM"
    else
        speedSelector.label.text="900 RPM"
    end
end

local enablePIDt=window:addChild(GUI.switchAndLabel(75, 5, 16, 6, 0xFFFF00, 0x1D1D1D, 0xAAAA22, 0xAAAA22, "Manual", false))
enablePIDt.switch.onStateChanged = function()
    if enablePIDt.switch.state then
        enablePIDt.label.text="Auto PID"
        turbine.setActive(true)
        tIprev=0
        tErrprev=0
    else
        enablePIDt.label.text="Manual"
    end
end

---------------------------------------------- TURBINE DASHBOARD ИНФО ТУРБИНЫ
local turbineRPMp=window:addChild(GUI.progressBar(76, 6, 38, 0x8A2BE2, 0x1D1D1D, 0x000000, 80, true, false))

window:addChild(GUI.image(75, 7, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/rpm.pic")))
local turbineRPM=window:addChild(GUI.text(80, 8, 0x8A2BE2, "RPM"))

window:addChild(GUI.image(75, 9, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/rf.pic")))
local turbineRFT=window:addChild(GUI.text(80, 10, 0x8A2BE2, "RF/tick"))

window:addChild(GUI.image(75, 11, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/eff.pic")))
local turbineEff=window:addChild(GUI.text(80, 12, 0x8A2BE2, "%"))

---------------------------------------------- FLOW СТРУЙКА
window:addChild(GUI.image(95, 7, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/plus.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        if keyboard.isShiftDown() then
            if keyboard.isControlDown() then
                turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()+1000)
            else
            turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()+10)
            end
        elseif keyboard.isControlDown() then
            turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()+100)
        else
            turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()+1)
        end
    end
end

window:addChild(GUI.image(100, 7, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/flow.pic")))
local turbineFlow=window:addChild(GUI.text(110, 8, 0x8A2BE2, "9999 mB/t"))

window:addChild(GUI.image(105, 7, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/minus.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        if keyboard.isShiftDown() then
            if keyboard.isControlDown() then
                turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()-1000)
            else
            turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()-10)
            end
        elseif keyboard.isControlDown() then
            turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()-100)
        else
            turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()-1)
        end
    end
end
---------------------------------------------- COIL КАТУШЕНЦИЯ
window:addChild(GUI.image(95, 9, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/coil.pic")))
local engageCoil = window:addChild(GUI.switch(100, 10, 8, 0xFFD700, 0x3D3D1D, 0xEEEEEE, turbine.getInductorEngaged()))
engageCoil.eventHandler=function(bullshit1, bullshit2, e1, ...)--костыль дающий пинка по выключателю
    if e1 == "touch" then
        engageCoil.state = not turbine.getInductorEngaged()
        turbine.setInductorEngaged(engageCoil.state)

		engageCoil:addAnimation(
			function(animation)
				if engageCoil.state then
					engageCoil.pipePosition = number.round(1 + animation.position * (engageCoil.width - 2))
				else	
					engageCoil.pipePosition = number.round(1 + (1 - animation.position) * (engageCoil.width - 2))
				end
			end
		):start(engageCoil.animationDuration)
	end
end

---------------------------------------------- ВЁДРА|Відра|Buckets
local tVentData=window:addChild(GUI.text(110, 13, 0xFFFF00, "Overflow"))--сам мод не имеет такой функции, чтобы получить состояние клапана. но разраб уже может добавить
turbine.setVentOverflow() --Middle mode

window:addChild(GUI.image(95, 12, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/ventg.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        turbine.setVentAll()
        tVentData.color=0x00FF00
        tVentData.text="Exhaust"
    end
end
window:addChild(GUI.image(100, 12, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/venty.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        turbine.setVentOverflow()
        tVentData.color=0xFFFF00
        tVentData.text="Overflow"
    end
end
window:addChild(GUI.image(105, 12, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/ventr.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        turbine.setVentNone()
        tVentData.color=0xFF0000
        tVentData.text="Closed"
    end
end

-------------------------------------------------------------------------------------------- ЧАЙНИК|for dummies
window:addChild(GUI.image(0, 3, imageL.load(filesystem.path(system.getCurrentScript()).."Resources/kettle.pic"))).eventHandler = function(bullshit1, bullshit2, useful, ...)
    if useful == "touch" then
        enablePIDr.switch.setState(enablePIDr.switch,true)
        enablePIDt.switch.setState(enablePIDt.switch,true)
        enablePIDr.switch.onStateChanged()
        enablePIDt.switch.onStateChanged()
    end
end
window:addChild(GUI.text(1, 11, 0x8A2BE2, "Just click me!"))
-------------------------------------------------------------------------------------------- END СТОПЭ
window.actionButtons.close.onTouch = function()
    event.removeHandler(mainhandler)
    reactor.setActive(false)--Turn off dangerous stuff
    turbine.setActive(false)
    window:remove()
    workspace:draw()
end



mainhandler=event.addHandler(function()
    local temperatura=reactor.getFuelTemperature()
    local reactivity=reactor.getFuelReactivity()

    turbineRPMp.value=number.roundToDecimalPlaces(turbine.getRotorSpeed()/20)                                      --Скорость ротора турбины|Швидкість ротора турбіни|Turbine rotor speed (%)
    turbineRPM.text=n2s(number.roundToDecimalPlaces(turbine.getRotorSpeed())).." RPM"                              --Скорость ротора турбины|Швидкість ротора турбіни|Turbine rotor speed (RPM)
    turbineRFT.text=number.shorten(number.roundToDecimalPlaces(turbine.getEnergyProducedLastTick()), 2).."RF/tick" --Выход энергии|Вихід енергії|Energy output (RF/tick)
    turbineEff.text=n2s(number.roundToDecimalPlaces(turbine.getBladeEfficiency())).."%"                            --КПД ротора|ККД ротору|Blade efficiency (%)
    turbineFlow.text=n2s(number.roundToDecimalPlaces(turbine.getFluidFlowRateMax())).."mB/t"                       --Поток пара|Потік пару|Steam flow (mB/t)

    reactorTemperature.text=n2s(number.roundToDecimalPlaces(reactor.getCasingTemperature())).."°С" --Температура реактора|Reactor temperature (°С)
    reactorOut.text = n2s(reactor.getHotFluidProducedLastTick()).."mB/tick"                        --Выход пара|Вихід пару|Steam output (mB/t)
    reactorFuel.text = number.roundToDecimalPlaces(reactor.getFuelConsumedLastTick(),3).."mB/tick" --Расход топлива|Розхід палива|Fuel usage (mB/t)
    reactorEff.text = n2s(reactor.getFuelReactivity()).."%"                                        --Реактивность|Реактивність|Reactivity (%)
    reactorRod.text=n2s(reactor.getControlRodLevel(0)).."%"                                        --Регуляция|Регуляція|Control rod level(%)

    enableReactorr.switch.setState(enableReactorr.switch,reactor.getActive())--Обновляем данные выключателей|Оновлюємо дані вимикачів|Updating switch state
    enableTurbinee.switch.setState(enableTurbinee.switch,turbine.getActive())
    engageCoil.setState(engageCoil,turbine.getInductorEngaged())

    local mainRPMValue=number.roundToDecimalPlaces(turbine.getRotorSpeed())--Меняем цвет от оборотов|Змінюємо колір від обертань|Change color by RPM
    if mainRPMValue==0 then
        turbineRPMp.colors.active=0x444444
    elseif mainRPMValue<510 then
        turbineRPMp.colors.active=0x0000CC
    elseif (510<mainRPMValue and mainRPMValue<720) or (1070<mainRPMValue and mainRPMValue<1640) then
        turbineRPMp.colors.active=0x00FFFF
    elseif (720<mainRPMValue and mainRPMValue<1070) or (1640<mainRPMValue and mainRPMValue<1820) then
        turbineRPMp.colors.active=0x00FF00
    elseif 1820<mainRPMValue and mainRPMValue<2000 then
        turbineRPMp.colors.active=0xFFFF00
    elseif mainRPMValue>2000 then
        turbineRPMp.colors.active=0xFF0000
    end

    if enablePIDt.switch.state==true then
        local RPMSelected=900
        if speedSelector.switch.state==true then RPMSelected=1800 end

        local tErr=RPMSelected-turbine.getRotorSpeed()
        local tP = Tp * tErr 
        local tI = tIprev + Ti * tErr-- PID регулятор|PID regulator
        local tD = Td * (tErr - tErrprev)
        local tOutput = number.roundToDecimalPlaces(tP + tI + tD);

        tIprev=tI
        tErrprev=tErr
        
        if turbine.getRotorSpeed() > RPMSelected-50 then  turbine.setInductorEngaged(true) end --оверклокинг| Overclocking
        if turbine.getRotorSpeed() < RPMSelected-400 then  turbine.setInductorEngaged(false) end --оверклокинг| Overclocking
        engageCoil.setState(engageCoil,turbine.getInductorEngaged())
        turbine.setFluidFlowRateMax(tOutput)
    end

    if enablePIDr.switch.state==true then
        local TEMPERATURESelected=reactorTemperatureS.value
        local rErr=TEMPERATURESelected-reactor.getCasingTemperature()
        local rP = Rp * rErr 
        local rI = rIprev + Ri * rErr-- PID регулятор|PID regulator
        local rD = Rd * (rErr - rErrprev)
        local rOutput = -1*number.roundToDecimalPlaces(rP + rI + rD);

        if rOutput>100 then rOutput=100 end--Ограничение|Обмеження|Limitation
        if rOutput<0 then rOutput=0 end

        rIprev=rI
        rErrprev=rErr
        reactor.setAllControlRodLevels(rOutput)
    end

--internet.request("http://reactordata.com/"..number.roundToDecimalPlaces(reactor.getCasingTemperature()))
--Раскомментировать для построения графиков PID регулятора (больше на GitHub)
--Розкоментувати для побудови графіків PID регулятора (більше на GitHub)
--Uncomment this for plotting graph of PID regulation (watch GitHub)

end,0.5)

---------------------------------------------

workspace:draw()
while true do
    workspace:start(0)
end