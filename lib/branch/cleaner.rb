require "branch/cleaner/version"
require "optparse"
require 'Time'

module Branch
  module Cleaner
  	NOBLE_BRANCHES_NAMES = ["master", "develop"]
  	DEFAULT_WEEKS = 2
    DEFAULT_PROFIXS = ['keep']

  	options = {}
  	OptionParser.new do |opts|
  		opts.banner = "bcleaner is a tool to clean branch which is out of date. master and develop branch is being protected."

  		opts.on('-p', '--push', 'push to remote repo.') do 
  			options[:push] = true
  		end

  		opts.on('-w NUMBER', '--week NUMBER', 'number of weeks. If last commit of branch if before the date, the branch will be deleted.') do |value|
    		options[:weeks] = Float(value) rescue DEFAULT_WEEKS
  		end

      opts.on('-b PROFIXA,PROFIXB', '--branch-profixs PROFIXA,PROFIXB', Array, 'profixs of branch that is protected from being deleting. For default value is [keep], a branch with name "keep/branch_subname" will be protected from being deleting, while a branch with name "keep_branch_subname" will not.') do |value|
        options[:protected_profixs] = Array(value) rescue DEFAULT_PROFIXS
      end
  	end.parse!

  	exec_command_result = `for branch in \`git branch -r | grep -v HEAD\`;do echo -e \`git show --format="%ci %cr" $branch | head -n 1\` $branch; done | sort -r`	

  	if exec_command_result.empty?
  		puts "no remote branches."
  		exit
  	end

		all_remote_branches = exec_command_result.split("\n")

    protected_profixs = options[:protected_profixs] || DEFAULT_PROFIXS
    protected_branches = all_remote_branches.select do |branch|
      valid_branch_name = branch.split(' ').last.split('/', 2).last

      protected_profixs.include?(valid_branch_name.split('/').first)
    end

    puts  <<-FOO
these branches will be protected (branch profixs #{protected_profixs}) : \n#{protected_branches.join("\n")}\n\n
     FOO

    not_protected_branches = all_remote_branches - protected_branches
		branches_to_delete = not_protected_branches.select do |branch|
			branch_time = Time.parse(branch)
			now_time = Time.new
			weeks = (now_time - branch_time) / 3600 / 24 / 7
      valid_branch_name = branch.split(' ').last.split('/', 2).last
      
			(weeks > (options[:weeks] || DEFAULT_WEEKS)) && !(NOBLE_BRANCHES_NAMES.include?(valid_branch_name)) 
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
