--[[ fancyclock.lua
lua script for the mechanical clock
Sunday, 20 October 2013 13:55
written by easysid

This program is free software. You are free, infact encouraged, to modify it as you deem fit, and freely distribute.

=====================================
Documentation: fancyclock.lua  (Also see README)
=====================================

======= Functions =======

run_gear(t) : Draws the gear using the given file.
draw_clock_hands(t) : Draws the hour and minute hands
draw_seconds(t) : Draws the seconds hand. Does not use images.
put_image(t) : Used to draw static images like clock body. Also, with rotate=true, used by other functions to draw rotated image.

*See the individual functions for params.

======== Images =========
The only important point is use of square images, as it allows for easier manipulation while rotating. See the README for a list of included resources.

Set the IMAGEPATH variable to point to the images used in the script.

]]--

require 'cairo'

-- Set the path to images below.
IMAGEPATH = "/home/siddharth/Conky/gear/"


function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, 
        conky_window.drawable, conky_window.visual, 
            conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    
    UPDATE_INT = conky_info["update_interval"]
    MAX = math.floor(60/UPDATE_INT)
    
    -- put gears
    run_gear({x=255, y=213, file='gear2.png', max=60, scale=0.75, tick=true})
    run_gear({x=300, y=250, scale=0.75, max=300})
    run_gear({x=350, y=215, scale=0.75, max=300, dir=-1})
    -- clock body
    put_image({x=300, y=250, file='clockbody.png', scale=0.5})
    -- clock hands
    draw_clock_hands({x=300, y=255, m_file='minute.png',m_scale=0.55,
    h_file='hour.png',h_scale=0.55})
    --another gear
    run_gear({x=300, y=253, scale=0.5})
    --seconds hand
    draw_seconds({x=300, y=253, length=130})
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end --end main()



function draw_clock_hands(t)
    --[[
        This function puts the minute and hour hands.
        Parameters: 6
        <mandatory>
        x, y : coordinates for the images
        m_file : image file to use for the minute hand
        h_file : image file to use for the hour hand

        <optional>
        m_scale : scaling factor for minute hand image (default 0.5)
        h_scale : scaling factor for hour hand image (default 0.5)
    ]]--

    local m_scale = t.m_scale or 0.5
    local h_scale = t.h_scale or 0.5
    local secs = tonumber(os.date("%S"))
    local minutes = tonumber(os.date("%M"))
    local hours = tonumber(os.date("%I"))
    --calculate the seconds for each
    local msecs = minutes*60 + secs
    local hsecs = hours*60*60 + msecs
    local m_theta = msecs*2*math.pi/3600 - math.pi/2
    local h_theta = hsecs*2*math.pi/43200 - math.pi/2
    -- draw the images
    put_image({x=t.x, y=t.y, file=t.m_file, scale=m_scale, theta=m_theta, rotate=true})
    put_image({x=t.x, y=t.y, file=t.h_file, scale=h_scale, theta=h_theta, rotate=true})
end


function draw_seconds(t)
    --[[
        This function draws the seconds hand. It does not use any images. Intead it draws using cairo line and arc.
        Paramters: 3 <all mamdatory>
        x, y : coordinates of seconds hand
        length : length of seconds hand.

        In addition to these, the parameter 'r', which is the radius of the circle at the base of seconds hand can be configured in the function itself.
    ]]--

    local R = t.length
    local r = 5 -- the radius of the small circle of seconds hand

    local updates = tonumber(conky_parse("${updates}"))
    local time = os.date('*t')
    if not up then up = updates- math.floor(time.sec/UPDATE_INT) end
    local value = (updates-up)%MAX
    local theta = value*2*math.pi/MAX - math.pi/2
    local x = t.x + R*math.cos(theta)
    local y = t.y + R*math.sin(theta)
    cairo_set_line_width(cr, 2)
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a({0xbb0408, 1}))
    cairo_arc(cr, t.x, t.y, r, 0, 2*math.pi)
    cairo_fill(cr)
    cairo_move_to(cr, t.x, t.y)
    cairo_line_to(cr, x,y)
    cairo_stroke(cr)
end --end draw_rolex


function run_gear(t)
    --[[
        Function to draw the gears.
        Parameters: 7
        <mandatory>
        x, y : image coords.
        <optional>
        file : image file to use (default 'gear1.png')
        max : maximum value for rotation. Note that higher values result in slower rotation. A good value is 300. (default MAX)
        dir : Direction of rotation. 1-clockwise, -1 anti. (default 1)
        scale : scaling factor. (default 1)
        tick (boolean): whether to mimic a tick or go smooth. Do not pass this arg if you want the smooth sweep.
    ]]--

    local file = t.file or 'gear1.png'
    local max = t.max or MAX
    local dir = t.dir or 1
    local scale = t.scale or 1
    local tick = t.tick or false
    if tick then
        local arg = t.arg or "${time %S}"
        value = tonumber(conky_parse(arg))
    else
        local updates = tonumber(conky_parse("${updates}"))
        value = updates%max
    end
    local theta = dir*value*2*math.pi/max - math.pi/2
    put_image({x=t.x, y=t.y, file=file, theta=theta, scale=scale, rotate=true})
end


function put_image(t)
    --[[
        function to put the images and rotate them.
        Params:
        <mandatory>
        x,y : coords
        file : image file
        <optional>
        scale : scaling factor (default 1)
        rotate (boolean): when set to true, rotates the image by angle theta
        theta : angle to rotate the image by. Required if rotate is true
    ]]--

    local scale = t.scale or 1
    local image = cairo_image_surface_create_from_png (IMAGEPATH..t.file);
    local w = cairo_image_surface_get_width (image);
    local h = cairo_image_surface_get_height (image);
    cairo_save(cr)
    cairo_translate (cr, t.x, t.y);
    if t.rotate then cairo_rotate(cr, t.theta) end
    cairo_scale  (cr, scale, scale);
    cairo_translate (cr, -0.5*w, -0.5*h);
    cairo_set_source_surface (cr, image, 0, 0);
    cairo_paint (cr);
    cairo_surface_destroy (image);
    cairo_restore(cr)
end


function rgba_to_r_g_b_a(tcolor)
    local color,alpha=tcolor[1],tcolor[2]
    return ((color / 0x10000) % 0x100) / 255.,
        ((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end --end rgba
