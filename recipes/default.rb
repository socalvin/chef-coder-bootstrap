#
# Install basic stuff
#
include_recipe 'build-essential'
include_recipe 'ntp'
include_recipe 'nginx'
include_recipe 'git'
include_recipe 'vim'
include_recipe "imagemagick"
include_recipe "redisio"
include_recipe "redisio::enable"
include_recipe "java"

#
# Define global variables
#
home_dir            = "/home/#{node[:coder][:user]}"
projects_dir        = "#{home_dir}/projects"
user                = "#{node[:coder][:user]}"
mysql_root_password = "#{node[:mysql][:server_root_password]}"

#
# Installl other packages
#
%w{libssl-dev libmysqlclient-dev mysql-server-5.6 libreadline-dev libsqlite3-dev libmagickwand-dev}.each do |pkg|
  package pkg do
    action :install
  end
end

#
# Set MySQL password
#
execute "Set MySQL root password" do
	command "mysqladmin -u root password '#{mysql_root_password}'"
	action :run
	ignore_failure true	
end

#
# Create a development user and group
#
group node[:coder][:group]
user node[:coder][:user] do
	supports :manage_home => true
	gid node[:coder][:group]
	home "#{home_dir}"
	shell "/bin/bash"
	password "$1$Zdw2mmK5$UyLns1FqaLPruywu7zxBu0"
end

#
# Add the just created development user to 'sudo' group
#
group 'sudo' do
	members node[:coder][:user]
	append  true
end

#
# Setup ssh keys
#
directory "#{home_dir}/.ssh" do
	owner user
	group user
	mode "0755"
	action :create
end
file "#{home_dir}/.ssh/id_rsa" do
	owner user
	group user
	mode "0600"
	content node[:ssh_keys][:private_key]
	action :create
end
file "#{home_dir}/.ssh/id_rsa.pub" do
	owner user
	group user
	mode "0600"
	content node[:ssh_keys][:public_key]
	action :create
end
file "#{home_dir}/.ssh/authorized_keys" do
	owner user
	group user
	mode "0600"
	content node[:ssh_keys][:public_key]
	action :create
end
template "#{home_dir}/.ssh/config" do
	source "ssh/config.erb"
	owner user
	group user
	mode 0600
	action :create
end

#
# Set up developer friendly prompt
# 
ruby_block "friendly-prompt" do
	block do
	file = Chef::Util::FileEdit.new("#{home_dir}/.bashrc")
	file.insert_line_if_no_match(
		"# Friendly prompt",
<<EOF

# Friendly prompt
parse_git_branch () {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \\(.*\\)/ (\\1)/'
}

parse_git_tag () {
	git describe --tags 2> /dev/null
}

parse_git_branch_or_tag() {
	local OUT="$(parse_git_branch)"
	if [ "$OUT" == " ((no branch))" ]; then
		OUT="[$(parse_git_tag)]";
	fi
	echo $OUT
}
RED="\\[\\033[0;31m\\]"
YELLOW="\\[\\033[0;33m\\]"
GREEN="\\[\\033[0;32m\\]"
NO_COLOUR="\\[\\033[0m\\]"
PS1="$GREEN\\u@\\h$NO_COLOUR:\\w$YELLOW\\$(parse_git_branch_or_tag)$NO_COLOUR\\$ "
EOF
	)
	file.write_file
	end
end

#
# Install rbenv and ruby
#
include_recipe "ruby_build"
include_recipe "rbenv::user_install"
execute "Install Ruby" do                                             
    command "su - #{user} -l -c 'rbenv install 2.2.1'" 	
    action :run   	
    not_if { File.exists? "#{home_dir}/.rbenv/versions/2.2.1" }
end
execute "Set rbenv global" do
    command "su - #{user} -l -c 'rbenv global 2.2.1'" 	
    action :run   		
end	
execute "Install bundler" do
    command "su - #{user} -l -c 'gem install bundler rails --no-rdoc --no-ri'" 	
    action :run   		
end

#
# Install Sublime Text
#
execute "install-sublime-text" do
  command "sudo add-apt-repository -y ppa:webupd8team/sublime-text-3; sudo apt-get update; sudo apt-get install -y sublime-text-installer"
end
execute "Create Sublime Text alias" do
	command "ln -s /opt/sublime_text/sublime_text /usr/bin/sublime"
	action :run
	not_if { File.exists? "/usr/bin/sublime" }	
end
