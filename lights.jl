abstract type Light end

struct PointLight <: Light
    position::vec3
    strength::Float32
end

get_random_position(p::PointLight) = p.position


# Hemisphere covering positive Z-axis, centered at origin
struct HemisphericalLight <: Light
    radius::Float32
    strength::Float32
end

function get_random_position(h::HemisphericalLight)
    pos = random_sphere_position()
    pos = vec3(pos.x, pos.y, abs(pos.z))
    return pos*h.radius
end