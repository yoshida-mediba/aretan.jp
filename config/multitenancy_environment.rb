# Copyright (C) 2014-2015 Antonio Terceiro
# Copyright (C) 2011-2014 Jérémy Lal
# Copyright (C) 2011-2014 Ondřej Surý
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'redmine/multi_tenancy'

if Redmine.tenant?

  # per-instance tmp/local cache directories
  config.paths['tmp'] = Redmine.root.join('tmp').to_s
  config.cache_store = :file_store, Redmine.root.join('tmp', 'cache').to_s

  # per-instance logs
  config.paths['log'] = Redmine.root.join('log', Rails.env + '.log').to_s

  # per-instance database configuration
  config.paths['config/database'] = Redmine.root.join('config', 'database.yml').to_s

  # per-instance session cookie
  path = ENV.fetch('RAILS_RELATIVE_URL_ROOT', '/')
  key = Redmine.name || '_redmine_session'
  config.session_store :cookie_store, :key => key, :path => path
  secret_file = Redmine.root.join('config', 'secret_key.txt')
  if File.exists?(secret_file)
    config.secret_key_base = File.read(secret_file).strip
  end

end
