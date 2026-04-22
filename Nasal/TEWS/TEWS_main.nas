# F-15 TEWS Display - AN/ALR-56C Radar Warning Receiver
# ---------------------------
# The RWR is a passive sensor. It detects radar emissions illuminating
# the aircraft, identifies emitter type, and displays bearing and relative
# signal strength. Distance from scope center represents signal strength
# (closer = stronger/more dangerous), NOT geographic range.
# The RWR cannot determine range to the emitter.
# ---------------------------
# Symbology (ref: DCS F-15C manual, Belsimtek):
#   Hat (^) above symbol    = airborne radar
#   Upper semi-circle       = newly detected threat (< 7 sec)
#   Diamond around symbol   = primary (highest priority) threat
#   Flashing circle         = missile launch warning
#   Text                    = emitter type code (e.g. "29"=MiG-29, "SD"=SA-11)
# ---------------------------
# Threat priority (descending):
#   1. ARH/SARH missile guidance detected
#   2. Tracking/STT lock
#   3. Emitter type: airborne > long-range SAM > mid-range > short-range > EW > AWACS
#   4. Signal strength
# ---------------------------
# Richard Harrison: 2015-01-23 (original), 2026-03-26 (rewrite)

var SCOPE_CX = 128;     # scope center x in 326x256 view
var SCOPE_CY = 128;     # scope center y
var SCOPE_R  = 110;     # scope radius pixels (matches old scale=220/2)
var INNER_R  = 55;      # inner ring radius
var MAX_SYMBOLS = 16;
var NEW_THREAT_TIME = 7; # seconds
var TEWS_FONT = "LiberationFonts/LiberationMono-Bold.ttf";
var TEWS_FONT_SIZE = 10;

# Emitter type database
# Keyed by FlightGear model name -> RWR display info
#   code  = symbol text shown on scope
#   cat   = A:airborne  G:ground-SAM  S:ship  E:EW/AWACS
#   dr    = display_range: nm at which signal places emitter at scope edge
#           (higher = more powerful transmitter, visible at greater range)
#   pri   = threat priority (lower = more dangerous, displayed first)
#   min_r = minimum radius fraction (0.5 for EW/AWACS = never in inner ring)
var EMITTER_DB = {
    # Airborne fighters
    "f-14b":            {code:"14",  cat:"A", dr: 60, pri:10, min_r:0.05},
    "F-14D":            {code:"14",  cat:"A", dr: 60, pri:10, min_r:0.05},
    "F-15C":            {code:"15",  cat:"A", dr: 60, pri:10, min_r:0.05},
    "F-15D":            {code:"15",  cat:"A", dr: 60, pri:10, min_r:0.05},
    "F-16":             {code:"16",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "YF-16":            {code:"16",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "f16":              {code:"16",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "F/A-18C":          {code:"18",  cat:"A", dr: 55, pri:10, min_r:0.05},
    "MiG-21bis":        {code:"21",  cat:"A", dr: 40, pri:10, min_r:0.05},
    "MiG-29":           {code:"29",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "SU-27":            {code:"27",  cat:"A", dr: 60, pri:10, min_r:0.05},
    "Su-15":            {code:"SU",  cat:"A", dr: 45, pri:10, min_r:0.05},
    "JA37-Viggen":      {code:"37",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "AJ37-Viggen":      {code:"37",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "AJS37-Viggen":     {code:"37",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "JA37Di-Viggen":    {code:"37",  cat:"A", dr: 50, pri:10, min_r:0.05},
    "m2000-5":          {code:"M2",  cat:"A", dr: 55, pri:10, min_r:0.05},
    "m2000-5B":         {code:"M2",  cat:"A", dr: 55, pri:10, min_r:0.05},
    "Typhoon":          {code:"EF",  cat:"A", dr: 65, pri:10, min_r:0.05},
    "QF-4E":            {code:"F4",  cat:"A", dr: 45, pri:10, min_r:0.05},
    # Bombers / attack
    "B1-B":             {code:"B1",  cat:"A", dr: 70, pri:12, min_r:0.05},
    "Tu-95MR":          {code:"95",  cat:"A", dr: 80, pri:12, min_r:0.05},
    "Tu-160-Blackjack": {code:"BJ",  cat:"A", dr: 80, pri:12, min_r:0.05},
    "A-10":             {code:"A10", cat:"A", dr: 30, pri:12, min_r:0.05},
    "A-10-model":       {code:"A10", cat:"A", dr: 30, pri:12, min_r:0.05},
    # Helicopters / drones
    "ch53e":            {code:"H",   cat:"A", dr: 20, pri:14, min_r:0.05},
    "MQ-9":             {code:"MQ",  cat:"A", dr: 25, pri:14, min_r:0.05},
    # EW / AWACS (never in inner ring)
    "EC-137R":          {code:"50",  cat:"E", dr:300, pri:60, min_r:0.50},
    "RC-137R":          {code:"50",  cat:"E", dr:300, pri:60, min_r:0.50},
    "E-8R":             {code:"E8",  cat:"E", dr:300, pri:60, min_r:0.50},
    "EC-137D":          {code:"50",  cat:"E", dr:300, pri:60, min_r:0.50},
    "gci":              {code:"GC",  cat:"E", dr:300, pri:60, min_r:0.50},
    # Tankers (not threats, but have radar)
    "KC-137R":          {code:"KC",  cat:"E", dr:200, pri:65, min_r:0.50},
    "KC-137R-RT":       {code:"KC",  cat:"E", dr:200, pri:65, min_r:0.50},
    "707-TT":           {code:"KC",  cat:"E", dr:200, pri:65, min_r:0.50},
    "KC-30A":           {code:"KC",  cat:"E", dr:200, pri:65, min_r:0.50},
    "Voyager-KC":       {code:"KC",  cat:"E", dr:200, pri:65, min_r:0.50},
    "KC-10A":           {code:"KC",  cat:"E", dr:200, pri:65, min_r:0.50},
    "KC-10A-GE":        {code:"KC",  cat:"E", dr:200, pri:65, min_r:0.50},
    # Ground SAMs
    "buk-m2":           {code:"SD",  cat:"G", dr:100, pri:25, min_r:0.05},  # SA-11 Snow Drift
    "S-75":             {code:"02",  cat:"G", dr: 80, pri:30, min_r:0.05},  # SA-2 Fan Song
    "MIM104D":          {code:"P",   cat:"G", dr:120, pri:20, min_r:0.05},  # Patriot
    "s300":             {code:"10",  cat:"G", dr:150, pri:20, min_r:0.05},  # SA-10
    # Ships
    "missile_frigate":  {code:"SH",  cat:"S", dr:100, pri:30, min_r:0.05},
    "frigate":          {code:"SH",  cat:"S", dr:100, pri:30, min_r:0.05},
    "fleet":            {code:"SH",  cat:"S", dr:120, pri:30, min_r:0.05},
    "USS-LakeChamplain":{code:"SM",  cat:"S", dr:120, pri:25, min_r:0.05},
    "USS-NORMANDY":     {code:"SM",  cat:"S", dr:120, pri:25, min_r:0.05},
    "USS-OliverPerry":  {code:"SH",  cat:"S", dr:100, pri:30, min_r:0.05},
    "USS-SanAntonio":   {code:"SH",  cat:"S", dr:100, pri:30, min_r:0.05},
};

var lookup_emitter = func(model, target_class) {
    if (model != nil and contains(EMITTER_DB, model))
        return EMITTER_DB[model];
    # Fallback by target class
    if (target_class == "MARINE")
        return {code:"SH", cat:"S", dr:100, pri:30, min_r:0.05};
    if (target_class == "SURFACE")
        return {code:"U",  cat:"G", dr: 80, pri:30, min_r:0.05};
    return     {code:"U",  cat:"A", dr: 50, pri:15, min_r:0.05};
};

var clamp = func(v, lo, hi) v < lo ? lo : (v > hi ? hi : v);

var TEWSDisplay = {
    new : func (canvas_item) {
        var obj = {parents : [TEWSDisplay]};

        obj.canvas_obj = canvas.new({
            "name": "F-15 TEWS",
            "size": [1024, 1024],
            "view": [326, 256],
            "mipmapping": 1,
        });
        obj.canvas_obj.addPlacement({"node": canvas_item});
        obj.canvas_obj.setColorBackground(0.004, 0.176, 0, 0);

        var root = obj.canvas_obj.createGroup();

        # Static scope elements
        obj.drawScope(root);

        # Symbol pool
        obj.symbols = setsize([], MAX_SYMBOLS);
        for (var i = 0; i < MAX_SYMBOLS; i += 1)
            obj.symbols[i] = obj.createSymbol(root);

        # New threat tracking: callsign -> first_seen_time
        obj.threat_first_seen = {};

        # Amortise target scanning across frames: collection + priority sort
        # runs over 20 partitions, published list is rendered every frame.
        # Avoids per-frame O(n) work over the full awg_9.tgts_list.
        obj.process_targets = frame_utils.PartitionProcessor.new("TEWS-display", 20, nil);
        obj.threats_display = [];
        obj.scan_acc = [];

        obj.tews_on = 1;
        setlistener("sim/model/f15/controls/TEWS/brightness", func(v) {
            if (v != nil) obj.tews_on = v.getValue();
        });

        return obj;
    },

    drawScope : func(root) {
        # Scope perimeter dots (clock markers around the edge)
        var dot_r = 2;
        for (var deg = 0; deg < 360; deg += 30) {
            var rad = deg * D2R;
            var dx = SCOPE_CX + SCOPE_R * math.sin(rad);
            var dy = SCOPE_CY - SCOPE_R * math.cos(rad);
            root.createChild("path")
                .moveTo(dx + dot_r, dy)
                .arcSmallCW(dot_r, dot_r, 0, -dot_r * 2, 0)
                .arcSmallCW(dot_r, dot_r, 0,  dot_r * 2, 0)
                .setColor(0, 1, 0).setColorFill(0, 1, 0);
        }

        # Nose reference triangle at 12 o'clock
        root.createChild("path")
            .moveTo(SCOPE_CX, SCOPE_CY - SCOPE_R - 8)
            .lineTo(SCOPE_CX - 4, SCOPE_CY - SCOPE_R - 2)
            .lineTo(SCOPE_CX + 4, SCOPE_CY - SCOPE_R - 2)
            .lineTo(SCOPE_CX, SCOPE_CY - SCOPE_R - 8)
            .setColor(0, 1, 0).setColorFill(0, 1, 0);

        # Center ECM status X
        me.ecm_x = root.createChild("path")
            .moveTo(SCOPE_CX - 4, SCOPE_CY - 4)
            .lineTo(SCOPE_CX + 4, SCOPE_CY + 4)
            .moveTo(SCOPE_CX + 4, SCOPE_CY - 4)
            .lineTo(SCOPE_CX - 4, SCOPE_CY + 4)
            .setColor(0, 1, 0).setStrokeLineWidth(1.5);
    },

    createSymbol : func(root) {
        var sym = {};
        sym.group = root.createChild("group").hide();

        # Emitter type code text (centered at group origin)
        sym.text = sym.group.createChild("text")
            .setAlignment("center-center")
            .setColor(0, 1, 0)
            .setFont(TEWS_FONT).setFontSize(TEWS_FONT_SIZE);

        # Hat caret (^) for airborne threats, above text
        sym.hat = sym.group.createChild("path")
            .moveTo(-5, -9).lineTo(0, -14).lineTo(5, -9)
            .setColor(0, 1, 0).setStrokeLineWidth(1.5)
            .hide();

        # Upper semi-circle: new threat marker (arc curving upward above text)
        sym.new_mark = sym.group.createChild("path")
            .moveTo(-9, -7)
            .arcSmallCW(9, 7, 0, 18, 0)
            .setColor(0, 1, 0).setStrokeLineWidth(1.5)
            .hide();

        # Diamond: primary threat marker
        var d = 13;
        sym.diamond = sym.group.createChild("path")
            .moveTo(0, -d).lineTo(d, 0).lineTo(0, d).lineTo(-d, 0).lineTo(0, -d)
            .setColor(0, 1, 0).setStrokeLineWidth(1.5)
            .hide();

        # Launch warning circle (flashing) - full circle around symbol
        var lr = 15;
        sym.launch_circle = sym.group.createChild("path")
            .moveTo(lr, 0)
            .arcSmallCW(lr, lr, 0, -lr * 2, 0)
            .arcSmallCW(lr, lr, 0,  lr * 2, 0)
            .setColor(0, 1, 0).setStrokeLineWidth(1.5)
            .hide();

        # Lower semi-circle (flashing) - missile guiding on your aircraft
        sym.guide_mark = sym.group.createChild("path")
            .moveTo(-9, 7)
            .arcSmallCW(9, 7, 0, 18, 0)
            .setColor(0, 1, 0).setStrokeLineWidth(1.5)
            .hide();

        return sym;
    },

    update : func(notification) {
        if (!me.tews_on) return;

        var heading = notification.OrientationHeadingDeg;
        var elapsed = notification.elapsed or 0;
        var now = systime();

        # Missile warning system properties (read via emexec notification)
        var launch_cs  = notification.launch_callsign or "";
        var semi_cs    = notification.semi_callsign or "";
        var maw_active = notification.maw_active or 0;
        var maw_bearing = notification.maw_bearing or 0;
        var flash = 5 * (elapsed - int(elapsed)) > 2.5; # ~2.5Hz blink

        # Collection pass is amortised across frames via PartitionProcessor.
        # Per-item work (DB lookup, bearing, first-seen bookkeeping) runs on
        # a slice of the target list each frame; end_fn sorts and publishes
        # me.threats_display for the per-frame renderer below.
        me.process_targets.process(me, awg_9.tgts_list,
            func(pp, obj, data) {
                obj.scan_acc = [];
            },
            func(pp, obj, u) {
                if (!u.get_RWR_visible()) return 1;
                var range = u.get_range();
                if (range < 0.1) return 1;

                var model = nil;
                if (u.Model != nil) model = u.Model.getValue();

                # Contacts with no model are non-threat (transponder/IFF only)
                var is_threat = (model != nil and model != "");
                var emitter = is_threat ? lookup_emitter(model, u.class)
                                       : {code:"--", cat:"X", dr:50, pri:70, min_r:0.50};

                # Radial position: signal strength proxy.
                # Larger display_range (more powerful emitter) sits closer to centre.
                var radius_frac = clamp(range / emitter.dr, emitter.min_r, 1.0);

                var bearing = u.get_deviation(heading);
                var cs = "";
                if (u.Callsign != nil) cs = u.Callsign.getValue();

                # First-seen bookkeeping for the new-threat marker
                if (cs != "" and !contains(obj.threat_first_seen, cs))
                    obj.threat_first_seen[cs] = now;
                var is_new = (cs != "" and (now - obj.threat_first_seen[cs]) < NEW_THREAT_TIME);

                var is_launching = (cs != "" and (cs == launch_cs or cs == semi_cs));
                var pri = is_launching ? 1 : emitter.pri;

                append(obj.scan_acc, {
                    emitter: emitter,
                    radius_frac: radius_frac,
                    bearing: bearing,
                    callsign: cs,
                    is_new: is_new,
                    is_launching: is_launching,
                    sort_key: pri + radius_frac,
                });
                return 1;
            },
            func(pp, obj, data) {
                var sorted = sort(obj.scan_acc, func(a, b) a.sort_key - b.sort_key);
                if (size(sorted) > MAX_SYMBOLS)
                    sorted = subvec(sorted, 0, MAX_SYMBOLS);
                obj.threats_display = sorted;

                # Purge stale first-seen entries (older than 30s) once per cycle
                foreach (var cs; keys(obj.threat_first_seen))
                    if (now - obj.threat_first_seen[cs] > 30)
                        delete(obj.threat_first_seen, cs);
            });

        # Per-frame render list: published scan results plus a live MAW symbol.
        # MAW is injected each frame (not via the partitioned scan) so the
        # missile warning reacts immediately rather than waiting a full cycle.
        var threats = me.threats_display;
        if (maw_active) {
            var maw_dev = geo.normdeg180(maw_bearing - heading);
            threats = [{
                emitter: {code:"M", cat:"A", dr:50, pri:1, min_r:0.05},
                radius_frac: 0.25,
                bearing: maw_dev,
                callsign: "_MAW_",
                is_new: 1,
                is_launching: 1,
                sort_key: 0,
            }] ~ threats;
            if (size(threats) > MAX_SYMBOLS)
                threats = subvec(threats, 0, MAX_SYMBOLS);
        }

        # Position symbols on scope
        for (var i = 0; i < MAX_SYMBOLS; i += 1) {
            var sym = me.symbols[i];
            if (i >= size(threats)) {
                sym.group.hide();
                continue;
            }

            var t = threats[i];
            var r = SCOPE_R * t.radius_frac;
            var b_rad = t.bearing * D2R;
            var x = SCOPE_CX + r * math.sin(b_rad);
            var y = SCOPE_CY - r * math.cos(b_rad);

            sym.group.setTranslation(x, y);
            sym.group.show();

            # Emitter type code
            sym.text.setText(t.emitter.code);

            # Hat caret for airborne threat radars (not for non-threat contacts)
            sym.hat.setVisible(t.emitter.cat == "A");

            # Upper semi-circle for newly detected threats only
            sym.new_mark.setVisible(t.is_new and t.emitter.cat != "X");

            # Diamond for primary threat (first after sort, must be a real threat)
            sym.diamond.setVisible(i == 0 and t.emitter.cat != "X");

            # Launch warning circle (flashing) - shown when this emitter has
            # launched a missile at us (callsign matches rwr-launch or MAW-semiactive)
            sym.launch_circle.setVisible(t.is_launching and flash);

            # Lower semi-circle (flashing) - missile actively guiding on us
            # Shown for the MAW "M" symbol and semi-active guidance sources
            sym.guide_mark.setVisible(t.is_launching and t.callsign == semi_cs and flash);
        }
    },
};

input = {
    OrientationHeadingDeg : "orientation/heading-deg",
    elapsed               : "sim/time/elapsed-sec",
    launch_callsign       : "sound/rwr-launch",
    semi_callsign         : "payload/armament/MAW-semiactive-callsign",
    maw_active            : "payload/armament/MAW-active",
    maw_bearing           : "payload/armament/MAW-bearing",
};

emexec.ExecModule.register("F15-TEWS", input, TEWSDisplay.new("TEWSImage"), 4);
