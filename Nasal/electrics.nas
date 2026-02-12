#
# F-15 Electrical System: Misc (EMMISC)
# ---------------------------
# Manages caution lights, and electrics controls
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2014-11-23; based on my F-14 version


# Constants

var oil_pressure_l = props.globals.getNode("engines/engine[0]/oil-pressure-psi", 1);
var oil_pressure_r = props.globals.getNode("engines/engine[1]/oil-pressure-psi", 1);
var ca_oil_press_light  = props.globals.getNode("sim/model/f15/lights/ca-oil-press", 1);

var bingo      = props.globals.getNode("sim/model/f15/controls/fuel/bingo", 1);
var ca_bingo_light  = props.globals.getNode("sim/model/f15/lights/ca-bingo-fuel", 1);

var ca_canopy_light = props.globals.getNode("sim/model/f15/lights/ca-canopy-lock", 1);
var canopy = props.globals.getNode("canopy/position-norm", 1);
canopy.setValue(0);

var ca_ramp_light = props.globals.getNode("sim/model/f15/lights/ca-l-inlet", 1);

var masterCaution_light = props.globals.getNode("sim/model/f15/instrumentation/warnings/master-caution", 1);
var masterCaution_light_set = props.globals.getNode("sim/model/f15/controls/master-caution-set", 1);
var lightTest = props.globals.getNode("sim/model/f15/lights/master-test-lights",1);
var electricsPowered = props.globals.getNode("fdm/jsbsim/systems/electrics/ac-essential-bus",1);
masterCaution_light_set.setDoubleValue(0);

var jettisonLeft = props.globals.getNode("controls/armament/station[2]/jettison-all", 1);
var jettisonRight = props.globals.getNode("controls/armament/station[7]/jettison-all", 1);

var ca_l_gen_light  = props.globals.getNode("sim/model/f15/lights/ca-l-gen-out", 1);
var ca_r_gen_light  = props.globals.getNode("sim/model/f15/lights/ca-r-gen-out", 1);

var ca_l_inlet_light  = props.globals.getNode("sim/model/f15/lights/ca-l-inlet", 1);
var ca_r_inlet_light  = props.globals.getNode("sim/model/f15/lights/ca-r-inlet", 1);

var ca_l_fuel_press_light  = props.globals.getNode("sim/model/f15/lights/ca-l-bst-pmp", 1);
var ca_r_fuel_press_light  = props.globals.getNode("sim/model/f15/lights/ca-r-bst-pmp", 1);

var ca_fuel_low  = props.globals.getNode("sim/model/f15/lights/ca-fuel-low", 1);

var ca_hyd_press_light  = props.globals.getNode("sim/model/f15/lights/ca-hydraulic", 1);

var l_eng_starter = props.globals.getNode("controls/engines/engine[0]/starter",1);
var r_eng_starter = props.globals.getNode("controls/engines/engine[1]/starter",1);

var l_eng_running = props.globals.getNode("engines/engine[0]/running",1);
var r_eng_running = props.globals.getNode("engines/engine[1]/running",1);
var ca_start_valve  = props.globals.getNode("sim/model/f15/lights/ca-start-valve", 1);
setprop("sim/model/f15/controls/hud/on-off",1);
setprop("sim/model/f15/controls/electrics/emerg-gen-switch",1);
setprop("sim/model/f15/controls/electrics/l-gen-switch",1);
setprop("sim/model/f15/controls/electrics/r-gen-switch",1);

var dlg_ground_services  = gui.Dialog.new("dialog[2]","Aircraft/F-15/Dialogs/ground-services.xml");
var dlg_lighting  = gui.Dialog.new("dialog[3]","Aircraft/F-15/Dialogs/lighting.xml");

    ## initialise the electrics / hyds
    setprop("fdm/jsbsim/systems/electrics/ac-essential-bus",115);
    setprop("fdm/jsbsim/systems/electrics/ac-left-main-bus",115);
    setprop("fdm/jsbsim/systems/electrics/ac-right-main-bus",115);
    setprop("fdm/jsbsim/systems/electrics/dc-essential-bus",28);
    setprop("fdm/jsbsim/systems/electrics/dc-left-bus",28);
    setprop("fdm/jsbsim/systems/electrics/dc-right-bus",28);
    setprop("fdm/jsbsim/systems/electrics/dc-main-bus",28);
    setprop("fdm/jsbsim/systems/electrics/egenerator-kva",0);
    setprop("fdm/jsbsim/systems/electrics/emerg-generator-status",0);
    setprop("fdm/jsbsim/systems/electrics/lgenerator-kva",75);
    setprop("fdm/jsbsim/systems/electrics/rgenerator-kva",75);
    setprop("fdm/jsbsim/systems/electrics/transrect-online",2);
    setprop("fdm/jsbsim/systems/hydraulics/pc1-psi",3000);
    setprop("fdm/jsbsim/systems/hydraulics/pc2-psi",3000);
    setprop("fdm/jsbsim/systems/hydraulics/util-psi",3000);
    setprop("engines/engine[0]/oil-pressure-psi", 28);
    setprop("engines/engine[1]/oil-pressure-psi", 28);

var masterCaution =  0;
var master_caution_active  = 0;

var caution_active = {};      # tracks logically active cautions (prevents master caution re-trigger)
var last_emmisc_time = 0;     # for dt calculation
var emmisc_dt = 0;            # frame delta-time (set in runEMMISC)
var panel_bulb_count = 0;     # number of active bulbs this frame

check_caution = func(mprop, caution_light, test_fn=nil, trigger_master=1){
    var active = 0;
    if (test_fn != nil)
        active = test_fn(mprop);
    else
        active = getprop(mprop);

    if (active)
    {
        if (trigger_master and !contains(caution_active, caution_light) or caution_active[caution_light] == 0)
            masterCaution = 1;
        caution_active[caution_light] = 1;
        master_caution_active = 1;
        panel_bulb_count += 1;
        setprop(caution_light, 1);
    }
    else
    {
        caution_active[caution_light] = 0;
        setprop(caution_light, 0);
    }
}

var runEMMISC = func {

# disable if we are in replay mode
#	if ( getprop("sim/replay/time") > 0 ) { return }

    set_console_lighting();
#
# all spring loaded switches
    if (!getprop("fdm/jsbsim/systems/electrics/dc-essential-bus-powered"))
    {
        setprop("sim/model/f15/controls/windshield-heat",0);
        setup_als_lights(0);
    }
    else
        setup_als_lights(1);


    setprop("systems/electrical/outputs/DG", getprop("fdm/jsbsim/systems/electrics/ac-left-main-bus"));

    masterCaution =  masterCaution_light_set.getValue();
    master_caution_active  = 0;
    panel_bulb_count = 0;

    # dt for panel thermal model
    var now = getprop("sim/time/elapsed-sec");
    emmisc_dt = now - last_emmisc_time;
    last_emmisc_time = now;
    if (emmisc_dt > 1) emmisc_dt = 0.1; # clamp on first call or after pause

    check_caution("sim/model/f15/controls/engine/engine-crank", "sim/model/f15/lights/ca-start-valve",
        func(p) {
            var c = getprop(p);
            return ((c==1 or l_eng_starter.getBoolValue()) and l_eng_running.getBoolValue())
                or ((c==2 or r_eng_starter.getBoolValue()) and r_eng_running.getBoolValue());
        });

    check_caution("fdm/jsbsim/systems/hydraulics/pc1-psi", "sim/model/f15/lights/ca-hydraulic",
        func(p) getprop(p) < 2100
            or getprop("fdm/jsbsim/systems/hydraulics/pc2-psi") < 2100
            or getprop("fdm/jsbsim/systems/hydraulics/util-psi") < 2100);

    check_caution("engines/engine[0]/oil-pressure-psi", "sim/model/f15/lights/ca-oil-press",
        func(p) oil_pressure_l.getValue() < 23 or oil_pressure_r.getValue() < 23);

    check_caution("engines/engine[0]/oil-pressure-psi", "sim/model/f15/lights/ca-l-bst-pmp",
        func(p) getprop(p) < 23);

    check_caution("engines/engine[1]/oil-pressure-psi", "sim/model/f15/lights/ca-r-bst-pmp",
        func(p) getprop(p) < 23);

    check_caution("fdm/jsbsim/systems/electrics/lgenerator-kva", "sim/model/f15/lights/ca-l-gen-out",
        func(p) getprop(p) < 50);

    check_caution("fdm/jsbsim/systems/electrics/rgenerator-kva", "sim/model/f15/lights/ca-r-gen-out",
        func(p) getprop(p) < 50);

    check_caution("fdm/jsbsim/systems/hydraulics/util-pressure", "sim/model/f15/lights/ca-l-inlet",
        func(p) !getprop(p));

    check_caution("fdm/jsbsim/systems/hydraulics/util-pressure", "sim/model/f15/lights/ca-r-inlet",
        func(p) !getprop(p));

    check_caution("sim/model/f15/controls/fuel/bingo", "sim/model/f15/lights/ca-bingo-fuel",
        func(p) total_lbs < bingo.getValue());

    check_caution("consumables/fuel/total-fuel-lbs", "sim/model/f15/lights/ca-fuel-low",
        func(p) getprop(p) < 1000);

    check_caution("canopy/position-norm", "sim/model/f15/lights/ca-canopy-lock",
        func(p) canopy.getValue() > 0);

    # ANTI-SKID does not trigger master caution
    check_caution("controls/gear/brake-parking", "sim/model/f15/lights/ca-anti-skid", nil, 0);

    check_caution("gear/tailhook/position-norm", "sim/model/f15/lights/ca-hook", func(p) getprop(p) > 0.2);
    check_caution("fdm/jsbsim/systems/ecs/oxygen-quantity-liters", "sim/model/f15/lights/ca-oxygen", func(p) getprop(p) < 2);
    # JFS LOW does not trigger master caution per TO 1F-15A-1 p.1-56
    check_caution("fdm/jsbsim/systems/hydraulics/jfs-accumulator-psi", "sim/model/f15/lights/ca-jfs-low",
        func(p) getprop(p) < 500, 0);

    check_caution("sim/model/f15/controls/AFCS/autopilot-disengage", "sim/model/f15/lights/ca-auto-plt");
    check_caution("gear/launchbar/position-norm", "sim/model/f15/lights/ca-launch-bar",
        func(p) getprop(p) and (getprop("controls/engines/engine[0]/throttle") < 0.95 or getprop("controls/engines/engine[1]/throttle") < 0.95));
    check_caution("sim/model/f15/controls/CAS/cas-yaw-enable", "sim/model/f15/lights/ca-cas-yaw", func(p) !getprop(p));

    # windshield hot: flashing if anti-ice air overtemp, steady if anti-ice is on
    var wndshld_overtemp = getprop("fdm/jsbsim/systems/ecs/windscreen-temperature-k") > 338;
    var wndshld_heat_on = getprop("fdm/jsbsim/systems/ecs/windscreen-heat-active");

    if (wndshld_overtemp)
    {
        # Flashing - anti-ice air hot
        if (!getprop("sim/model/f15/lights/ca-wndshld-hot-flash"))
        {
            setprop("sim/model/f15/lights/ca-wndshld-hot-flash",1);
            masterCaution = 1;
        }
        setprop("sim/model/f15/lights/ca-wndshld-hot",0);
        master_caution_active = 1;
    }
    else if (wndshld_heat_on)
    {
        # Steady - windshield anti-ice is on (informational)
        if (!getprop("sim/model/f15/lights/ca-wndshld-hot"))
        {
            setprop("sim/model/f15/lights/ca-wndshld-hot",1);
            masterCaution = 1;
        }
        setprop("sim/model/f15/lights/ca-wndshld-hot-flash",0);
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-wndshld-hot"))
        {
            setprop("sim/model/f15/lights/ca-wndshld-hot",0);
        }
        if (getprop("sim/model/f15/lights/ca-wndshld-hot-flash"))
        {
            setprop("sim/model/f15/lights/ca-wndshld-hot-flash",0);
        }
    }

    check_caution("fdm/jsbsim/fcs/roll-ratio-emergency", "sim/model/f15/lights/ca-roll-ratio");
    check_caution("fdm/jsbsim/fcs/pitch-ratio-emergency", "sim/model/f15/lights/ca-pitch-ratio");
    check_caution("sim/model/f15/controls/CAS/cas-roll-enable", "sim/model/f15/lights/ca-cas-roll", func(p) !getprop(p));
    check_caution("sim/model/f15/controls/CAS/cas-pitch-enable", "sim/model/f15/lights/ca-cas-pitch", func(p) !getprop(p));
check_caution("fdm/jsbsim/propulsion/engine[0]/bleedair-temp-high", "sim/model/f15/lights/ca-l-bleed-air");
check_caution("fdm/jsbsim/propulsion/engine[1]/bleedair-temp-high", "sim/model/f15/lights/ca-r-bleed-air");
check_caution("fdm/jsbsim/propulsion/openv-total-temp-too-high", "sim/model/f15/lights/ca-tot-temp-hi");

check_caution("fdm/jsbsim/propulsion/engine[0]/eec-fail", "sim/model/f15/lights/ca-l-eng-contr");
check_caution("fdm/jsbsim/propulsion/engine[1]/eec-fail", "sim/model/f15/lights/ca-r-eng-contr");

# EMER BST ON - emergency generator activated
check_caution("fdm/jsbsim/systems/electrics/emerg-gen-active", "sim/model/f15/lights/ca-emer-bst-on");

# Undriven caution lights - 3D objects and XML animations exist but no trigger logic yet.
# Per TO 1F-15A-1 (Figures 3-8 / 3-9) the conditions are:
#   ca-attitude     : INS/attitude reference failure or comparison monitor trip
#   ca-av-bit       : avionics built-in-test failure detected  [no master caution]
#   ca-bst-sys-mal  : boost system malfunction (dual BLC or pitch/roll boost failure)
#   ca-ecs          : ECS turbine overtemp or flow control valve fault
#   ca-fuel-hot     : fuel temperature exceeds limit (fuel-oil heat exchanger overtemp)
#   ca-iff-mode-4   : IFF Mode 4 crypto failure or no-go reply  [no master caution]
#   ca-inlet-ice    : engine inlet ice detected (ice detector signal)
#   ca-xfer-pump    : fuel transfer pump failure or low output pressure
#   ca-rud-l-mtr    : rudder limiter motor fault (limiter actuator disagree)
#
# Per TO 1F-15A-1 p.1-56 the following lights do NOT trigger master caution:
#   AV BIT, JFS LOW, SPD BK OUT, IFF MODE 4 (SPARE)

    # wndshld-hot is not in caution_active hash — count it separately
    if (getprop("sim/model/f15/lights/ca-wndshld-hot") or getprop("sim/model/f15/lights/ca-wndshld-hot-flash"))
        panel_bulb_count += 1;

    # Master test illuminates all 37 bulbs
    if (lightTest.getValue())
        panel_bulb_count = 37;

    setprop("sim/model/f15/lights/caution-panel-active-bulb-count", panel_bulb_count);

    var panel_heating = getprop("sim/model/f15/lights/caution-panel-heating-rate-per-bulb") or 0.02;
    var panel_cooling = getprop("sim/model/f15/lights/caution-panel-cooling-coeff") or 0.008;
    var cockpit_k = getprop("fdm/jsbsim/systems/ecs/cockpit-temperature-k") or 293;
    var panel_temp = getprop("sim/model/f15/lights/caution-panel-temperature_k") or cockpit_k;
    var overheat_k = getprop("sim/model/f15/lights/caution-panel-overheat-k") or 358.15;

    # When overheated the lights flash (0.3s on / 0.3s off) so heating duty cycle drops to 50%
    var flash_on = getprop("sim/model/f15/lights/flash-on-time-sec") or 0.3;
    var flash_off = getprop("sim/model/f15/lights/flash-off-time-sec") or 0.3;
    var duty_cycle = (panel_temp > overheat_k) ? flash_on / (flash_on + flash_off) : 1.0;

    panel_temp += emmisc_dt * (panel_bulb_count * panel_heating * duty_cycle - panel_cooling * (panel_temp - cockpit_k));
    setprop("sim/model/f15/lights/caution-panel-temperature_k", panel_temp);

    if (jettisonLeft.getValue() or jettisonRight.getValue()){
        masterCaution = 1;
        master_caution_active = 1;
        jettisonRight.setValue(0);
        jettisonLeft.setValue(0);
    }

    if (!master_caution_active or electricsPowered.getValue() < 5){
        masterCaution_light_set.setBoolValue(0);
        masterCaution_light.setDoubleValue(0);
    }
    else
    {
        if (masterCaution or lightTest.getValue())
        {
            masterCaution_light.setDoubleValue(1);
        }
    }
}

var master_caution_pressed = func {
    jettisonLeft.setValue(0);
    jettisonRight.setValue(0);
    masterCaution_light.setBoolValue(0);
    masterCaution_light_set.setBoolValue(0);

    setprop("sim/model/f15/controls/AFCS/autopilot-disengage",0);
}

var electricsFrame = func {
    runEMMISC();
}



var set_console_lighting = func
{
    var v = getprop("controls/lighting/l-console");
    setprop("controls/lighting/l-console-norm", v/10);
    if (getprop("fdm/jsbsim/systems/electrics/dc-main-bus-powered") and v > 0)
        setprop("controls/lighting/l-console-eff-norm", v/10);
    else
        setprop("controls/lighting/l-console-eff-norm", 0);

    v = getprop("controls/lighting/r-console");
    setprop("controls/lighting/r-console-norm", v/10);
    if (getprop("fdm/jsbsim/systems/electrics/dc-main-bus-powered") and v > 0)
        setprop("controls/lighting/r-console-eff-norm", v/10);
    else
        setprop("controls/lighting/r-console-eff-norm", 0);

}


setlistener("controls/lighting/l-console", func(prop)
            {
                set_console_lighting();
            }, 1, 0);

setlistener("controls/lighting/r-console", func(prop)
            {
                set_console_lighting();
            }, 1, 0);

#
#
# master gen panel 
setlistener("sim/model/f15/controls/electrics/l-gen-switch", func
{
    var v = getprop("sim/model/f15/controls/electrics/l-gen-switch");
    if(v != nil)
    {
        if (v)
        {
            setprop("fdm/jsbsim/systems/electrics/lgenerator-status", 1);
        }
        else
        {
            setprop("fdm/jsbsim/systems/electrics/lgenerator-status", 0);
        }
    }
}, 1, 0);

setlistener("sim/model/f15/controls/electrics/r-gen-switch", func
{
    var v = getprop("sim/model/f15/controls/electrics/r-gen-switch");
    if(v != nil)
    {
        if (v)
        {
            setprop("fdm/jsbsim/systems/electrics/rgenerator-status", 1);
        }
        else
        {
            setprop("fdm/jsbsim/systems/electrics/rgenerator-status", 0);
        }
    }
}, 1, 0);

setlistener("sim/model/f15/controls/electrics/emerg-gen-switch", func {
    var v = getprop("sim/model/f15/controls/electrics/emerg-gen-switch");
    if (v != nil) {
        # 0=OFF, 1=AUTO (normal), 2=MAN, 3=ISOLATE
        setprop("fdm/jsbsim/systems/electrics/emerg-gen-mode", v);
        setprop("fdm/jsbsim/systems/electrics/emerg-generator-status", v > 0 ? 1 : 0);
    }
}, 1, 0);

#
# master test panel selection switch 
var master_test_select_switch = func(n) {
var curval = getprop("sim/model/f15/controls/electrics/master-test-switch");
if (curval == nil)
curval = 0;

curval = curval + n;
if (curval < 0) curval = 10;
if (curval > 10) curval = 0;

    setprop("sim/model/f15/controls/electrics/master-test-switch", curval);
if (curval == 0)
{
setprop("sim/model/f15/lights/master-test-nogo",0);
setprop("sim/model/f15/lights/master-test-go",0);
setprop("sim/model/f15/lights/master-test-lights",0);
}
else if (curval == 10)
{
setprop("sim/model/f15/lights/master-test-lights",1);
setprop("sim/model/f15/lights/master-test-nogo",0);
setprop("sim/model/f15/lights/master-test-go",1);
}
else
{
setprop("sim/model/f15/lights/master-test-lights",0);
setprop("sim/model/f15/lights/master-test-nogo",1);
setprop("sim/model/f15/lights/master-test-go",0);
}
}

#
# Use ALS secondary lighting 
# The scheme we adopt is to use both lights in one place to make the landing light brighter and spread
# them for the taxi light. These lights move with the view (as I suspect they are setup for being on the mlg
# not on the nose gear - but it is a lot better than just darkness).
# also remember that these only illuminate the runway as proper lighting calculating is not done; this is a shader
# level implementation that is fast rather than accurate.
# ref: http://wiki.flightgear.org/ALS_technical_notes#ALS_secondary_lights
var setup_als_lights = func(dc_power)
{
    var light_setting=getprop("sim/multiplay/generic/int[6]");

#
# gear needs to be extended (not just commanded)
# view needs to be internal (otherwise geometry of the shader is wrong).
# needs electrical power
    if (dc_power != nil and dc_power == 0)
    {
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 0);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 0);
        return;
    }
    if (!getprop("sim/current-view/internal") 
        or getprop("gear/gear[0]/position-norm") == nil 
        or getprop("gear/gear[0]/position-norm") < 0.6  
        or !light_setting)
    {
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 0);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 0);
        return;
    }

    if (light_setting & 2)
    {
# put both lights at the same place and brighter for the landing light
        setprop("sim/rendering/als-secondary-lights/landing-light1-offset-deg", 0);
        setprop("sim/rendering/als-secondary-lights/landing-light2-offset-deg", 0);
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 1);
        return;
    }
    
    if (light_setting & 1)
    {
# spread the  lights for the taxi light
        setprop("sim/rendering/als-secondary-lights/landing-light1-offset-deg", 4);
        setprop("sim/rendering/als-secondary-lights/landing-light2-offset-deg", -4);
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 1);
        return;
    }
}

# only need this if we can get the bus-essential-powered as a listener too, otherwise the setup_als_lights is
# called in the main EMMISC loop
#setlistener("sim/current-view/internal", func {
#    aircraft.setup_als_lights(getprop("fdm/jsbsim/systems/electrics/dc-essential-bus-powered"));
#}, 1, 0);
#
#setlistener("sim/multiplay/generic/int[6]", func
#{
#    aircraft.setup_als_lights(getprop("fdm/jsbsim/systems/electrics/dc-essential-bus-powered"));
#
#}, 1, 0);
#
#setlistener("gear/gear[0]/position-norm", func
#{
#    aircraft.setup_als_lights(getprop("fdm/jsbsim/systems/electrics/dc-essential-bus-powered"));
#}, 1, 0);

setlistener("sim/model/f15/controls/windshield-heat", func 
{
    setprop("fdm/jsbsim/systems/ecs/windshield-heat",getprop("sim/model/f15/controls/windshield-heat"));
}, 1, 0);

