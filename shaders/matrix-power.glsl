// Matrix Power. Cursor red channel carries ZLE heat; movement animates all apps.
// Tune these values to change the intensity.
const float SPARK_STRENGTH = 1.4;
const float BACKGROUND_RAIN_STRENGTH = 0.40;
// Pixel sizes below are tuned for this terminal cell height (px). Shake and rain scale with the real cell.
const float REFERENCE_CELL_HEIGHT = 23.0;
const float SHAKE_PIXELS = 1.0;
// Welding-torch heat for contact flash and sparks, even where no shell reports heat.
const float SPARK_HEAT_FLOOR = 0.85;
const float GLASS_CURVATURE = 0.03;
const float SCANLINE_STRENGTH = 0.20;
// Edge darkening like a photo lens: 0 is off, 0.3 is slight, 0.6 is heavy.
const float VIGNETTE_STRENGTH = 0.30;
const float IDLE_RAIN_STRENGTH = 0.65;
const float IDLE_BLUR_PIXELS = 5.0;
// The idle look builds up slowly after focus is lost and releases quickly when focus returns.
const float IDLE_BUILD_SECONDS = 15.0;
const float IDLE_RELEASE_SECONDS = 0.6;
// While idle the rain eats the terminal: blocks of text drop out column by column and slide down.
// IDLE_ERODE_MAX is the share of blocks eaten at full build-up.
const float IDLE_ERODE_MAX = 0.95;
const float IDLE_FALL_FRACTION = 0.12;
const float IDLE_CONTENT_FADE = 0.88;
const float RAIN_GLOW_STRENGTH = 0.50;
// Higher values thin the glyph strokes: 0 keeps the full bitmap weight, 0.9 leaves only the cores.
const float RAIN_STROKE_THINNING = 0.60;
// Slightly rounded glass corners, as a fraction of the glass height.
const float GLASS_CORNER_RADIUS = 0.02;
// Window area outside the glass: the terminal background colour (config), so it reads as one surface.
const vec3 OUTSIDE_COLOR = vec3(0.031, 0.039, 0.043);
float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }
float segmentDistance(vec2 p, vec2 a, vec2 b) {
    vec2 edge = b - a;
    float along = clamp(dot(p - a, edge) / max(dot(edge, edge), 0.001), 0.0, 1.0);
    return length(p - a - edge * along);
}
// Real mirrored half-width katakana and digits, rasterized with CoreText.
const uint MATRIX_GLYPHS[605] = uint[605](
0u,0u,4177920u,1573760u,2032048u,458992u,196656u,98328u,57356u,0u,0u,0u,0u,3146496u,1835392u,917728u,901368u,786636u,786624u,786624u,64u,0u,0u,131072u,131104u,4178428u,1065228u,1589636u,1835392u,917696u,196720u,16u,0u,0u,0u,16384u,1507836u,131104u,131104u,131104u,196640u,1022u,0u,0u,0u,524288u,524480u,4178112u,918524u,983264u,622768u,581788u,524420u,128u,0u,0u,131072u,393312u,4177952u,3277820u,3343136u,3343152u,3244824u,1884620u,0u,0u,0u,65536u,196656u,2064816u,196734u,4063280u,517116u,393312u,393312u,96u,0u,0u,393216u,196704u,4129776u,3244824u,1622412u,786816u,393408u,229488u,16u,0u,0u,65536u,65584u,4161560u,836600u,803020u,786624u,458848u,98360u,0u,0u,0u,0u,2064384u,3146744u,3146496u,3146496u,3146496u,4162304u,1049596u,0u,0u,0u,0u,884952u,4186328u,885758u,884952u,786648u,393408u,229488u,16u,0u,0u,0u,114700u,3342392u,3203840u,1671580u,786816u,458848u,49212u,0u,0u,0u,0u,2064384u,1573368u,786624u,393408u,2031840u,3260856u,2114318u,0u,0u,0u,0u,65536u,65552u,4162320u,3261308u,1900944u,65680u,4128784u,480u,0u,0u,0u,3194880u,3195660u,1671960u,1573272u,786816u,393408u,196720u,16u,0u,0u,393216u,4128816u,3376112u,3392280u,1982972u,786880u,393408u,229488u,24u,0u,0u,0u,1032640u,393340u,393312u,394238u,196640u,196656u,114712u,8u,0u,0u,0u,3358720u,1295158u,2015660u,1573292u,786624u,393440u,98352u,0u,0u,0u,0u,2081272u,0u,4186112u,393724u,196640u,196656u,114712u,0u,0u,0u,32768u,32776u,32776u,229384u,1015928u,1606088u,32776u,32776u,8u,0u,0u,0u,393312u,393312u,4178942u,393312u,196640u,229424u,49176u,0u,0u,0u,0u,0u,2081276u,0u,0u,0u,4186112u,508u,0u,0u,0u,0u,4161536u,1573760u,1769872u,917744u,1966304u,1278448u,49180u,0u,0u,0u,393216u,393312u,2064892u,786816u,983264u,4178424u,394092u,393312u,96u,0u,0u,0u,3145984u,1573248u,1573248u,786624u,393312u,229424u,32796u,0u,0u,0u,0u,884736u,884952u,884952u,557272u,1622412u,3170700u,17158u,0u,0u,0u,0u,49164u,1622028u,508364u,49212u,49164u,49164u,2064892u,0u,0u,0u,0u,2080768u,1573372u,1573248u,786816u,917696u,458848u,114744u,0u,0u,0u,0u,0u,196656u,491640u,835788u,3694982u,7340800u,512u,0u,0u,0u,131072u,131104u,4186620u,688160u,1753324u,1753516u,3302182u,131878u,32u,0u,0u,0u,4186112u,3146750u,1573248u,884940u,458872u,393328u,262240u,0u,0u,0u,0u,2031736u,1049024u,229376u,1835248u,0u,1015868u,3670464u,0u,0u,0u,0u,196640u,196656u,65584u,884760u,1671384u,1622412u,3662844u,768u,0u,0u,0u,1573248u,1671552u,983288u,917728u,1769952u,1147696u,49164u,0u,0u,0u,0u,2080768u,197116u,196656u,197630u,196656u,196656u,1966576u,0u,0u,0u,32768u,1146904u,4178936u,1671454u,852368u,196624u,196656u,196656u,32u,0u,0u,0u,0u,1606136u,1573248u,524416u,786624u,786624u,1020u,0u,0u,0u,0u,4177920u,3146504u,3146496u,4162552u,3146496u,4162304u,3146748u,0u,0u,0u,0u,2064888u,0u,4177920u,3146496u,1573248u,786880u,196720u,0u,0u,0u,0u,1606024u,1606024u,1606024u,1622408u,786560u,917696u,229488u,16u,0u,0u,0u,491640u,491640u,491640u,2523240u,3588972u,2016236u,418022u,0u,0u,0u,0u,49164u,49164u,49164u,3195148u,1622412u,442572u,114748u,0u,0u,0u,0u,4177920u,3195900u,3195660u,3195660u,3195660u,4178700u,2147324u,0u,0u,0u,0u,2080768u,1065468u,1589636u,1573252u,786816u,393408u,196720u,0u,0u,0u,0u,16384u,3260430u,1147672u,1573248u,917696u,229488u,16414u,0u,0u,0u,0u,4178424u,7365390u,6317574u,6301190u,6317574u,3204870u,1016828u,0u,0u,0u,0u,983040u,786672u,786624u,786624u,786624u,786624u,786624u,192u,0u,0u,0u,2064384u,3204092u,7366150u,1835904u,491744u,49180u,8380422u,2046u,0u,0u,0u,4178424u,3171086u,3670784u,4129264u,6292224u,3171846u,2065406u,0u,0u,0u,0u,1835392u,1966560u,1802672u,1630620u,8384903u,1574910u,1573248u,0u,0u,0u,0u,4178940u,49164u,2088966u,3204094u,6293248u,3204868u,1016828u,0u,0u,0u,0u,4178424u,2155276u,2056198u,7398398u,6317574u,7390726u,2065404u,0u,0u,0u,0u,8380416u,3147774u,1835392u,917696u,458848u,196656u,229424u,24u,0u,0u,0u,4178424u,3171086u,3719942u,4178428u,6317830u,7366150u,2065406u,0u,0u,0u,0u,2081016u,3171086u,7366406u,8251142u,6293500u,3695360u,1016318u,0u,0u);
float matrixGlyphPixel(ivec2 pixel, int glyphIndex) {
    if (pixel.x < 0 || pixel.x >= 12 || pixel.y < 0 || pixel.y >= 22) return 0.0;
    uint rowPair = MATRIX_GLYPHS[glyphIndex * 11 + pixel.y / 2];
    uint bit = uint((pixel.y - (pixel.y / 2) * 2) * 12 + pixel.x);
    return float((rowPair >> bit) & 1u);
}
float matrixGlyph(vec2 p, int glyphIndex) {
    // Mirrored light katakana, interpolated for smooth phosphor strokes.
    vec2 samplePoint = vec2(1.0 - p.x, p.y) * vec2(12.0, 22.0) - 0.5;
    ivec2 pixel = ivec2(floor(samplePoint));
    vec2 blend = fract(samplePoint);
    float top = mix(matrixGlyphPixel(pixel, glyphIndex),
                    matrixGlyphPixel(pixel + ivec2(1, 0), glyphIndex), blend.x);
    float bottom = mix(matrixGlyphPixel(pixel + ivec2(0, 1), glyphIndex),
                       matrixGlyphPixel(pixel + ivec2(1, 1), glyphIndex), blend.x);
    return mix(top, bottom, blend.y);
}

// Where a column's stream head is, in rows from the top. The wash-away erosion reads the same
// head, so the terminal dissolves exactly where the green stream passes.
float rainStreamHead(float column, float layerSeed, float rows, float speedScale, float elapsed,
                     out float tailLength) {
    float columnSeed = hash(column + layerSeed);
    float speed = (4.0 + hash(column + layerSeed + 43.0) * 6.0) * speedScale;
    tailLength = 12.0 + columnSeed * 15.0;
    float period = rows + tailLength + 6.0;
    float delay = columnSeed * 2.8;
    // No wrapped tail: each stream enters above and exits below the screen.
    return mod(max(0.0, elapsed - delay) * speed, period) - 1.0;
}

// Shared glyph treatment for the independent background and idle streams.
vec3 matrixRain(vec2 glassCoord, vec2 res, float elapsed, float layerSeed,
                vec2 glyphSize, float speedScale, vec3 tailColor, vec3 headColor, float reveal) {
    // Metal coordinates start at the top; positive Y is down.
    vec2 grid = glassCoord / glyphSize;
    float column = floor(grid.x);
    float columnSeed = hash(column + layerSeed);
    float delay = columnSeed * 2.8;
    float tailLength;
    float head = rainStreamHead(column, layerSeed, res.y / glyphSize.y, speedScale, elapsed, tailLength);
    float behind = head - floor(grid.y);
    float stream = exp(-max(behind, 0.0) / (tailLength * 0.42))
        * (1.0 - smoothstep(tailLength - 2.0, tailLength, behind))
        * step(0.0, behind) * step(delay, elapsed)
        * smoothstep(columnSeed * 0.8, columnSeed * 0.8 + 0.2, reveal);
    // Integer selection avoids the precision loss of large sine-hash seeds.
    // Coprime strides give adjacent rows/columns different glyphs across all 55.
    uint glyphColumn = uint(max(column, 0.0));
    uint glyphRow = uint(max(floor(grid.y), 0.0));
    float phase = float((glyphColumn * 3u + glyphRow * 7u) % 9u) / 9.0;
    uint glyphTick = uint(floor(iTime * 0.8 + phase));
    int glyphIndex = int((glyphColumn * 17u + glyphRow * 31u
        + uint(layerSeed) + glyphTick * 13u) % 55u);
    vec2 point = fract(grid);
    float symbol = smoothstep(RAIN_STROKE_THINNING, 1.0, matrixGlyph(point, glyphIndex));
    vec2 radius = vec2(2.0 / 12.0, 2.0 / 22.0);
    float glow = (matrixGlyph(point + vec2(radius.x, 0.0), glyphIndex)
        + matrixGlyph(point - vec2(radius.x, 0.0), glyphIndex)
        + matrixGlyph(point + vec2(0.0, radius.y), glyphIndex)
        + matrixGlyph(point - vec2(0.0, radius.y), glyphIndex)) * 0.25;
    float tip = 1.0 - smoothstep(0.0, 1.8, behind);
    return mix(tailColor, headColor, tip)
        * (symbol + glow * RAIN_GLOW_STRENGTH) * stream;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Keep shader coordinates aligned with the terminal image so selection stays in place.
    vec2 outputSize = iResolution.xy;
    vec2 res = outputSize;
    vec2 viewportCoord = fragCoord;
    // The bowed glass: the outline uses the same warp as the content, so the edges bulge with it.
    vec2 screen = viewportCoord / res * 2.0 - 1.0;
    vec2 bowed = screen * (1.0 + GLASS_CURVATURE * screen.yx * screen.yx);
    // Rounded rectangle distance in the bowed space: negative inside the glass, positive outside.
    float cornerRadius = res.y * GLASS_CORNER_RADIUS;
    vec2 cornerOffset = abs(bowed) * res * 0.5 - res * 0.5 + cornerRadius;
    float glassEdge = length(max(cornerOffset, vec2(0.0))) + min(max(cornerOffset.x, cornerOffset.y), 0.0) - cornerRadius;
    if (glassEdge > 0.5) {
        fragColor = vec4(OUTSIDE_COLOR, 1.0);
        return;
    }
    vec2 cursorScale = res / outputSize;
    vec4 currentCursor = iCurrentCursor * vec4(cursorScale, cursorScale);
    vec4 previousCursor = iPreviousCursor * vec4(cursorScale, cursorScale);
    float cellScale = max(currentCursor.w, 12.0) / REFERENCE_CELL_HEIGHT;
    // The shell sets the cursor color with OSC 12: red carries heat, pure green means off.
    // iCursorColor is the live terminal color. It also follows a toggle sent while an app such
    // as Claude Code hides the cursor, when iCurrentCursorColor stays frozen.
    bool shellColorSet = any(greaterThan(iCursorColor, vec3(0.0)));
    if (shellColorSet && iCursorColor.b < 0.05 && iCursorColor.r < 0.05) {
        vec4 terminal = texture(iChannel0, viewportCoord / res);
        fragColor = terminal;
        return;
    }
    int effectFlags = int(floor(iCursorColor.b * 255.0 + 0.5));
    bool backgroundRainEnabled = (effectFlags & 1) != 0;
    bool idleAnimationEnabled = (effectFlags & 2) != 0;
    bool shakeEnabled = (effectFlags & 4) != 0;
    bool sparksEnabled = (effectFlags & 8) != 0;
    float age = max(0.0, iTime - iTimeCursorChange);
    float heat = clamp(iCursorColor.r, 0.0, 1.0) * exp(-age / 3.5);
    float burst = exp(-age * 7.0);
    float focusBurst = exp(-max(0.0, iTime - iTimeFocus) * 7.0);
    float sparkHeat = max(heat, SPARK_HEAT_FLOOR);
    // Focus alone controls the overlay: waiting for output never hides content.
    // Ghostty stamps only the moment focus is gained, never lost. While unfocused, build up from
    // the last cursor activity instead (or the last focus gain, if that is newer).
    float sinceFocusGain = max(0.0, iTime - iTimeFocus);
    float sinceActivity = max(0.0, iTime - max(iTimeFocus, iTimeCursorChange));
    float idleBuild = smoothstep(0.0, IDLE_BUILD_SECONDS, sinceActivity);
    float idleRelease = 1.0 - smoothstep(0.0, IDLE_RELEASE_SECONDS, sinceFocusGain);
    float idle = idleAnimationEnabled ? (iFocus > 0 ? idleRelease : idleBuild) : 0.0;
    // The green rain leads the rest of the build-up: it ramps in well ahead of the erosion and blur.
    float rainIdle = 1.0 - pow(1.0 - idle, 2.5);
    // Bounded times keep float32 trigonometry and hashes accurate however long the window is open.
    float wobble = mod(iTime, 64.0);
    vec2 shake = vec2(sin(wobble * 111.0), cos(wobble * 137.0))
        * SHAKE_PIXELS * cellScale * burst * float(shakeEnabled);
    // Sample a gently bowed screen. Warp every layer into the same glass.
    vec2 glassUV = bowed * 0.5 + 0.5;
    vec2 glassCoord = glassUV * res + shake;
    // Columns join the rain one by one, with the same ramp and order as the green streams. Each
    // stream washes away the content along its path, and the holes stay behind as the build-up deepens.
    vec2 rainCell = vec2(22.0, 34.0) * cellScale;
    float eatenColumn = floor(glassUV.x * res.x / rainCell.x);
    float columnSeed = hash(eatenColumn + 1703.0);
    float columnVisible = smoothstep(columnSeed * 0.8, columnSeed * 0.8 + 0.2, rainIdle);
    float streamTail;
    float streamRow = rainStreamHead(eatenColumn, 1703.0, res.y / rainCell.y, 1.0, iTime, streamTail);
    float passedRows = streamRow - floor(glassUV.y * res.y / rainCell.y);
    float wash = step(0.0, passedRows) * exp(-max(passedRows, 0.0) / (streamTail * 1.2));
    float erosion = columnVisible * clamp(idle * 0.6 + rainIdle * wash * 0.7, 0.0, 1.0);
    float fall = erosion * erosion * IDLE_FALL_FRACTION * res.y * (0.3 + hash(eatenColumn + 77.0));
    vec2 uv = clamp((glassCoord - vec2(0.0, fall)) / res, vec2(0.0), vec2(1.0));
    vec2 eatenBlock = floor((glassUV * res - vec2(0.0, fall)) / (rainCell * 0.5));
    float blockSeed = hash(eatenBlock.x * 91.0 + eatenBlock.y * 37.0 + 5.0);
    float gone = smoothstep(blockSeed, blockSeed + 0.1, erosion * IDLE_ERODE_MAX);
    vec4 base = texture(iChannel0, uv);
    vec3 color = base.rgb;
    // Defocus the terminal under the idle overlay, preserving sharp rain above it.
    if (idle > 0.001) {
        vec2 blurStep = vec2(IDLE_BLUR_PIXELS * idle) / res;
        vec3 blurred = base.rgb * 0.25;
        for (int j = 0; j < 4; j++) {
            float angle = float(j) * 1.5707963;
            vec2 direction = vec2(cos(angle), sin(angle));
            blurred += texture(iChannel0, clamp(uv + direction * blurStep,
                vec2(0.0), vec2(1.0))).rgb * 0.125;
            vec2 diagonal = vec2(direction.x - direction.y, direction.x + direction.y);
            blurred += texture(iChannel0, clamp(uv + diagonal * blurStep,
                vec2(0.0), vec2(1.0))).rgb * 0.0625;
        }
        color = mix(color, blurred, idle) * (1.0 - idle * IDLE_CONTENT_FADE);
    }
    color *= 1.0 - gone;
    // Small phosphor halo, preserving ANSI colors and sharp text.
    vec3 halo = vec3(0.0);
    for (int j = 0; j < 4; j++) {
        float a = float(j) * 1.5707963;
        vec2 delta = vec2(cos(a), sin(a)) * 2.0 * cellScale / res;
        halo += texture(iChannel0, clamp(uv + delta, vec2(0), vec2(1))).rgb;
    }
    color += halo * (0.018 + heat * 0.025) * (1.0 - idle);
    vec2 cursor = currentCursor.xy + vec2(currentCursor.z, -currentCursor.w) * 0.5;
    vec2 p = glassCoord - cursor;
    float cell = max(currentCursor.w, 12.0);
    vec3 green = mix(vec3(0.04, 1.0, 0.30), vec3(0.72, 1.0, 0.84), heat);
    color += green * exp(-length(p) / (cell * (0.6 + heat))) * (0.10 + heat * 0.30) * (1.0 - idle);
    // Plasma contact point: white-hot core with an electric green corona.
    // No contact flash on a stationary, cold cursor.
    float contact = max(burst, focusBurst) * (0.25 + sparkHeat * 0.75);
    color += vec3(0.40, 1.0, 0.66) * exp(-length(p) / (cell * 1.6)) * contact * 0.55;
    color += vec3(0.88, 1.0, 0.96) * exp(-length(p) / (cell * 0.19)) * contact * 2.8;
    // A short molten seam follows the most recently cut character.
    vec2 previous = previousCursor.xy + vec2(previousCursor.z, -previousCursor.w) * 0.5;
    if (abs(previous.y - cursor.y) < cell && distance(previous, cursor) < cell * 5.0) {
        float seam = segmentDistance(glassCoord, previous, cursor);
        color += vec3(0.25, 1.0, 0.55) * exp(-seam / 1.5) * contact * 0.55;
    }
    // Bright elongated chips fly upward, arc under gravity, and cool to amber.
    // Stagger their initial ages so a fast typist still sees a full spark fan.
    // Each keystroke lands on its own millisecond, so a stamp that wraps every 8 s still gives
    // each spark fan a new pattern. An unbounded stamp breaks the sine hash after a few minutes
    // of uptime and folds all sparks into one short streak.
    float stamp = mod(floor(iTimeCursorChange * 1000.0), 8192.0);
    if (sparksEnabled && age < 0.9 && length(p) < cell * 24.0) {
        for (int j = 0; j < 28; j++) {
            float seed = float(j) * 17.0 + stamp;
            float life = 0.28 + hash(seed + 9.0) * 0.58;
            float t = age + hash(seed + 2.0) * 0.16;
            float fade = 1.0 - smoothstep(life * 0.30, life, t);
            float angle = 0.15 + hash(seed) * 2.84;
            float speed = cell * (7.0 + hash(seed + 4.0) * 15.0) * (0.65 + sparkHeat * 0.65);
            vec2 velocity = vec2(cos(angle), -sin(angle)) * speed;
            vec2 gravity = vec2(0.0, cell * 15.0);
            vec2 head = velocity * t + gravity * t * t;
            float tailTime = max(0.0, t - (0.012 + hash(seed + 6.0) * 0.027));
            vec2 tail = velocity * tailTime + gravity * tailTime * tailTime;
            float d = segmentDistance(p, tail, head);
            float width = 0.65 + hash(seed + 7.0) * 0.75;
            float core = exp(-d * d / (width * width));
            float glow = exp(-d / (width * 3.5)) * 0.24;
            vec3 hot = vec3(0.83, 1.0, 0.91);
            vec3 ember = mix(vec3(0.12, 1.0, 0.38), vec3(1.0, 0.42, 0.06), hash(seed + 5.0));
            vec3 sparkColor = mix(hot, ember, smoothstep(0.04, life, t));
            color += sparkColor * (core + glow) * fade * SPARK_STRENGTH;
        }
    }
    float dark = 1.0 - smoothstep(0.04, 0.30, max(base.r, max(base.g, base.b)));
    // The grayscale background runs on its own clock, including while typing.
    vec3 backgroundRain = matrixRain(glassCoord, res, iTime, 901.0,
        vec2(20.0, 32.0) * cellScale, 0.75, vec3(0.11), vec3(0.32), 1.0);
    color += backgroundRain * BACKGROUND_RAIN_STRENGTH * dark * dark
        * float(backgroundRainEnabled);
    // A second, green overlay is visible only while this surface is unfocused.
    if (idle > 0.001) {
        vec3 idleRain = matrixRain(glassCoord, res, iTime,
            1703.0, vec2(22.0, 34.0) * cellScale, 1.0,
            vec3(0.025, 0.72, 0.15), vec3(0.72, 1.0, 0.80), rainIdle);
        color += idleRain * rainIdle * IDLE_RAIN_STRENGTH * mix(dark * dark, 1.0, rainIdle);
    }
    // A small heat bar in the lower right: empty when cool, white at full heat.
    vec2 meter = glassCoord - vec2(res.x - 170.0, res.y - 28.0);
    if (meter.x >= 0.0 && meter.x <= 140.0 && meter.y >= 0.0 && meter.y <= 4.0) {
        vec3 meterColor = mix(vec3(0.025, 0.12, 0.05), green, step(meter.x, 140.0 * heat));
        color = mix(meterColor, color, idle);
    }
    // Four pixels per scanline at the reference cell size, scaled with the cell so every display
    // shows the same lines per character. Keep it still
    // to avoid flicker, with just enough darkening to show the phosphor rows.
    float scanline = 0.5 + 0.5 * cos(glassCoord.y / cellScale * 1.5707963);
    color *= 1.0 - SCANLINE_STRENGTH * scanline;
    float vignette = 1.0 - VIGNETTE_STRENGTH * pow(clamp(dot(screen, screen) * 0.5, 0.0, 1.0), 1.4);
    color *= vignette;
    fragColor = vec4(mix(OUTSIDE_COLOR, clamp(color, 0.0, 1.0), 1.0 - smoothstep(-0.5, 0.5, glassEdge)), base.a);
}
