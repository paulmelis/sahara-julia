using Gtk

win = GtkWindow("My First Gtk.jl Program", 400, 200)

b = GtkButton("Click Me")
push!(win,b)

showall(win)

Gtk.gtk_main()