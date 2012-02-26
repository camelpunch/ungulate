package "git-core"
package "libmagickwand-dev"
gem_package "bundler"

execute "install ungulate gems" do
  cwd "/vagrant"
  user "vagrant"
  group "vagrant"
  command "bundle install --path=/home/vagrant/.bundle"
end

execute "run ungulate test suite" do
  cwd "/vagrant"
  user "vagrant"
  group "vagrant"
  command "bundle exec rake"
end

