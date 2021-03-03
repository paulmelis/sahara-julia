struct vec3 <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
    
    vec3() = new(0f0, 0f0, 0f0)
    vec3(x, y, z) = new(x, y, z)
end

function Base.show(io::IO, v::vec3)
    print(io, "<vec3 $(v.x) $(v.y) $(v.z)>")
end


normalized(v::vec3) = v / norm(v)

+(v::vec3, w::vec3) = vec3(v.x+w.x, v.y+w.y, v.z+w.z)
-(v::vec3, w::vec3) = vec3(v.x-w.x, v.y-w.y, v.z-w.z)
*(v::vec3, f::AbstractFloat) = vec3(v.x*f, v.y*f, v.z*f)
*(f::AbstractFloat, v::vec3) = vec3(v.x*f, v.y*f, v.z*f)

^(v::vec3, w::vec3) = vec3(
    v.y*w.z - v.z*w.y,
    v.z*w.x - v.x*w.z,
    v.x*w.y - v.y*w.x
)

const mat4 = MMatrix{4,4,Float32}

mat4_zero() = zeros(mat4)
mat4_identity() = mat4(I)

function mat4_translate(tx, ty, tz) ::mat4
    m = mat4_identity()
    m[:,4] .= (tx, ty, tz, 1)
    return SMatrix(m)
end

function mat4_scale(sx, sy, sz) ::mat4
    m = mat4_identity()
    m[1,1] = sx
    m[2,2] = sy
    m[3,3] = sz
    return SMatrix(m)
end

function mat4_rot_x(angle) ::mat4
    angle_r = deg2rad(angle)
    c = cos(angle_r)
    s = sin(angle_r)
    m = mat4_zero()
    m[1,1] = 1.0f0
    m[2,2] = m[3,3] = c
    m[2,3] = s
    m[3,2] = -s
    m[4,4] = 1.0f0
    return SMatrix(m)
end

function mat4_rot_y(angle) ::mat4
    angle_r = deg2rad(angle)
    c = cos(angle_r)
    s = sin(angle_r)
    m = mat4_zero()
    m[1,1] = m[3,3] = c
    m[2,2] = 1.0f0
    m[1,3] = -s
    m[3,1] = s
    m[4,4] = 1.0f0
    return SMatrix(m)
end

function mat4_rot_z(angle) ::mat4
    angle_r = deg2rad(angle)
    c = cos(angle_r)
    s = sin(angle_r)
    m = mat4_zero()
    m[1,1] = m[2,2] = c    
    m[1,2] = s
    m[2,1] = -s
    m[3,3] = 1.0f0
    m[4,4] = 1.0f0    
    return SMatrix(m)
end

function mat4_rotate(angle, x, y, z) ::mat4
    # normalize axis if needed
    l = sqrt(x*x + y*y + z*z)
    if abs(l-1.0) > EPSILON
        x /= l
        y /= l
        z /= l
    end

    res = mat4_zero()

    angle_r = deg2rad(angle)
    c = cos(angle_r)
    s = sin(angle_r)
    
    # precalc 1-c
    m[1,1] = x*x*(1.0-c) + c
    m[1,2] = x*y*(1.0-c) + z*s
    m[1,3] = x*z*(1.0-c) - y*s

    m[2,1] = x*y*(1.0-c) - z*s
    m[2,2] = y*y*(1.0-c) + c
    m[2,3] = y*z*(1.0-c) + x*s

    m[3,1] = x*z*(1.0-c) + y*s
    m[3,2] = y*z*(1.0-c) - x*s
    m[3,3] = z*z*(1.0-c) + c

    m[4,4] = 1.0

    return SMatrix(m)
end


"""
Transform point p. Assumes p[4] == 1 and homogenizes the result
XXX do we ever use homogenized coordinates? I.e. we don't use perspective
transforms anywhere
"""
function ptransform(M::mat4, p::vec3) ::vec3

    inv_d = 1.0f0 / (M[4,1]*p.x + M[4,2]*p.y + M[4,3]*p.z + M[4,4])
    
    return vec3(
        (M[1,1]*p.x + M[1,2]*p.y + M[1,3]*p.z + M[1,4]) * inv_d,
        (M[2,1]*p.x + M[2,2]*p.y + M[2,3]*p.z + M[2,4]) * inv_d,
        (M[3,1]*p.x + M[3,2]*p.y + M[3,3]*p.z + M[3,4]) * inv_d
    )

end

"""
Transform vector v. Assumes p[4] == 0, i.e. disregards translation.
"""
function vtransform(M::mat4, v::vec3) ::vec3

    return vec3(
        (M[1,1]*v.x + M[1,2]*v.y + M[1,3]*v.z),
        (M[2,1]*v.x + M[2,2]*v.y + M[2,3]*v.z),
        (M[3,1]*v.x + M[3,2]*v.y + M[3,3]*v.z)
    )

end

"""
Transform normal n, i.e. transform with (M^-1)^T disregarding
any translation. Assumes |n| = 1
"""
function ntransform(M::mat4, n::vec3) ::vec3

    T = transpose(inv(M))

    return vec3(
        (T[1,1]*n.x + T[1,2]*n.y + T[1,3]*n.z),
        (T[2,1]*n.x + T[2,2]*n.y + T[2,3]*n.z),
        (T[3,1]*n.x + T[3,2]*n.y + T[3,3]*n.z)
    )

end
