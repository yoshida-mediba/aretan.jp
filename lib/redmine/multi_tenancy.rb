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

module Redmine

  class << self

    def tenant
      # X_DEBIAN_SITEID is kept here for backwards compatibility with existing
      # Debian installations.
      ENV['X_DEBIAN_SITEID'] || ENV['REDMINE_INSTANCE'] || 'default'
    end

    def tenant?
      !tenant.nil?
    end

    def root
      if tenant
        Pathname.new(File.join(Rails.root, 'instances', tenant))
      else
        Rails.root
      end
    end

  end

end
