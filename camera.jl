struct Framebuffer
    width::Int
    height::Int
    aspect::Float32
    
    Framebuffer(w, h) = new(w, h, w/h)    
end


mutable struct PerspectiveCamera
    framebuffer::Framebuffer
    
    position::vec3
    lookat::vec3
    forward::vec3
    right::vec3
    up::vec3
    
    vfov::Float32   # Degrees
    image_plane_width::Float32
    image_plane_height::Float32
    
    pixel_width::Float32
    pixel_height::Float32
    
    image_plane_topleft::vec3
    pixel_step_right::vec3
    pixel_step_down::vec3
    
    function PerspectiveCamera(framebuffer, position, lookat, up, vfov)
    
        obj = new(framebuffer)
    
        # Compute camera coordinate system from camera position, look-at point and up vector
        obj.position = position
        obj.lookat = lookat
        obj.forward = normalized(lookat - position)
        obj.right = normalized(obj.forward ^ up)
        obj.up = obj.right ^ obj.forward
                
        # Compute size of the image plane from the chosen field-of-view
        # and image aspect ratio. This is the size of the image plane at
        # a distance of one world unit from the camera position.
        obj.vfov = vfov
        obj.image_plane_height = 2 * tan(deg2rad(vfov)/2)
        obj.image_plane_width = obj.image_plane_height * framebuffer.aspect
        
        # The size of one pixel on the image plane.
        # In almost all cases these two values are equal (i.e. square pixels)
        obj.pixel_width = obj.image_plane_width / framebuffer.width
        obj.pixel_height = obj.image_plane_height / framebuffer.height
        
        # A pixel "step" on the image plane
        obj.pixel_step_right = obj.right * obj.pixel_width
        obj.pixel_step_down = (-obj.up) * obj.pixel_height

        # Compute top-left corner of image plane
        obj.image_plane_topleft = (obj.position 
            + obj.forward 
            + obj.right * (-obj.image_plane_width/2) 
            + obj.up * (obj.image_plane_height/2))
            
        return obj
    end    
    
end

function Base.show(io::IO, c::PerspectiveCamera)
    print(io, "<PerspectiveCamera pos=$(c.position) lookat=$(c.lookat) forward=$(c.forward) right=$(c.right) up=$(c.up)>")
end
