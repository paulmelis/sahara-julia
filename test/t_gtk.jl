# https://discourse.julialang.org/t/ensuring-gtk-jl-responsivity/40710/4
# XXX doesn't seem to update UI when dolongcomp() is running, unless -t >= 2
using Gtk
using LinearAlgebra
import Base.Threads.@spawn


b = Gtk.Button("oi")
ll = Gtk.Label("output")
hb = Gtk.Box(:v)
w = Gtk.Window("x")

push!(hb,b)
push!(hb,ll)
push!(w, hb)
state = :startcomp


signal_connect(b, "clicked") do widget
    global state
    if state == :startcomp
        @info "Button clicked 1"
        GAccessor.text(ll,"Running your long calculation...")
        state = :computing
        @spawn dolongcomp()
    end
end


function dolongcomp()
    global state

    niter = 100000000
    mypi = calcpi(niter)

    @info mypi
    GAccessor.text(ll,"done, mypy=$mypi")
    state = :startcomp
end


function calcpi(niter)
    acc = 0
    for n in 1:niter
        if norm(rand(2)) < 1.0
            acc += 1
        end
    end
    return 4*acc/niter
end


showall(w)

Gtk.gtk_main()