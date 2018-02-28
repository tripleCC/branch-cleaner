require "branch/cleaner/version"
require "optparse"
require 'Time'

module Branch
  module Cleaner
  	NOBLE_BRANCHES_NAMES = ["master", "develop"]

  	options = {}
  	OptionParser.new do |opts|
  		opts.banner = "bcleaner is a tool to clean branch which is out of date."

  		opts.on('-p', '--push', 'push to remote repo.') do 
  			options[:push] = true
  		end

  		opts.on('-w=NUMBER', '--week=NUMBER', 'number of weeks. If last commit of branch if before the date, the branch will be deleted.') do |value|
    		options[:weeks] = Float(value) rescue 2
  		end
  	end.parse!

  	exec_command_result = `for branch in \`git branch -r | grep -v HEAD\`;do echo -e \`git show --format="%ci %cr" $branch | head -n 1\` $branch; done | sort -r`	

  	if exec_command_result.empty?
  		puts "no remote branches."
  		exit
  	end

		all_remote_branches = exec_command_result.split("\n")
		branches_to_delete = all_remote_branches.select do |branch|
			branch_time = Time.parse(branch)
			now_time = Time.new
			weeks = (now_time - branch_time) / 3600 / 24 / 7
			(weeks > options[:weeks]) && !(NOBLE_BRANCHES_NAMES.include?(branch.split(' ').last.split('/', 2).last))
		end
		
		puts  <<-FOO
these branches will be deleted : \n#{branches_to_delete.join("\n")}
		 FOO

		branches_to_delete.each do |branch|
			branch_name = branch.split(' ').last.split('/', 2).last
			puts "deleing branch 【 #{branch} 】..." 

			`git push -d origin #{branch_name}`
		end if options[:push]

  	exit
  end
end
