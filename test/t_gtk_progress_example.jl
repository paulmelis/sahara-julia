# https://discourse.julialang.org/t/threading-1-3-success-story/27111
# Works, but high system time
using Gtk.ShortNames

b = Box(:v)
win = Window(b,"test")

button = Button("do work")
push!(b,button)

pb = ProgressBar()
push!(b,pb)

Gtk.showall(win)

function doWork()
  N = 20
  for k=1:N
    set_gtk_property!(pb,:fraction,(k-1)/(N-1) )
    sum(collect(1:100000000)) # some heavy work
  end
end

signal_connect(button, "clicked") do widget
  Threads.@spawn doWork()
end

Gtk.gtk_main()