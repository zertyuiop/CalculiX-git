#!/usr/bin/ruby
directory = "./" 
project_name = "sp3"
max_threads_num = 14
repo_name = "https://github.com/zertyuiop/CalculiX-git"
reload_time = 1

work_file = project_name + ".frd"
solver = "/usr/bin/time -o " + project_name + ".time ccx -i " + project_name + " 2>&1 | tee -a " + project_name + ".dump"
dirs = Array.new
git = "git pull " + repo_name

system(git)
list = Dir.entries(directory).select {|entry| File.directory? File.join(directory,entry) and !(entry == "." || entry == ".." || entry == "lua-femtk" || entry == ".git") }
list.each do |exi|
    Dir.chdir(exi)
    dirs.push(Dir.pwd) if File.exist?(work_file) == false 
	Dir.chdir("../")
end

exit(0) if dirs.size == 0

dirstmp = dirs
threads = []
threads_num = 0
gi = 0

begin
    if (threads_num < max_threads_num) && (dirstmp.size > 0)
        threads << Thread.new do
		    threads_num += 1
		    dr = dirstmp.shift 
	        Dir.chdir(dr)
	        system(solver)
		    Dir.chdir("../lua-femtk/")
		    postprocessor = "lua frd2exo.lua -f -2 -sets ../sets.nc -voln 100 -surfn 200 " + dr + work_file + dr + project_name + ".exo"
		    system(postprocessor)
		    Dir.chdir("../")
			dirs.delete(dr)
			threads_num -= 1
	    end
	end
	
	if gi >= reload_time * 1200.0
	    system(git) 
	    list1 = Dir.entries(directory).select {|entry| File.directory? File.join(directory,entry) and !(entry == "." || entry == ".." || entry == "lua-femtk") }
        list1 = list1.difference(list)
        list1.each do |exi|
            Dir.chdir(exi)
            dirs.push(Dir.pwd) if File.exist?(work_file) == false 
		    dirstmp.push(Dir.pwd) if File.exist?(work_file) == false 
	        Dir.chdir("../")
        end
		gi = 0
	end
	
	gi += 1
	sleep 3
end until dirs.size > 0

threads.each(&:join)

system("sudo shutdown -h now")
