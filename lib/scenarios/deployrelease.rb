module Scenarios
  ##
  # DeployRelease scenario
  class DeployRelease
    def run
      repo_dicts = Hash.new []
      repo_dicts['12trip']               = %w(OTT)
      repo_dicts['12trip-railways.node'] = %w(BLACKBOX)
      repo_dicts['12trip-whitelabel']    = %w(SOCIAL)
      repo_dicts['12trip_hotels']        = %w(HOTELS)
      repo_dicts['b2b_app']              = %w(B2B)
      repo_dicts['bundle-back']          = %w(BUNDLES)
      repo_dicts['front-avia']           = %w(XJSX_AVIA)
      repo_dicts['front-cars']           = %w(XJSX_CARS)
      repo_dicts['front-hotels']         = %w(XJSX_HOTELS)
      repo_dicts['front-packages']       = %w(XJSX_PACKAGES)
      repo_dicts['front-railways']       = %w(XJSX_RAILWAYS)
      repo_dicts['front-tours']          = %w(XJSX_TOURS)
      repo_dicts['front-travel-vtb24']   = %w(FRONT_TRAVEL_VTB24)
      repo_dicts['hotels_backoffice']    = %w(FRONT_HOTELS_BO)
      repo_dicts['m-12trip']             = %w(MOBILE)
      repo_dicts['m-12trip_vk']          = %w(MFRONT_12TRIP_VK)
      repo_dicts['m-hotels']             = %w(MHOTELS)
      repo_dicts['renderer']             = %w(PASSBOOK)
      repo_dicts['seo_hotels']           = %w(SEOHOTELS)
      repo_dicts['seo_pages']            = %w(SEOPAGES)
      repo_dicts['twiket-live']          = %w(TLIVE)
      repo_dicts['twiket_backoffice']    = %w(BO)

      jira = JIRA::Client.new SimpleConfig.jira.to_h
      issue = jira.Issue.find SimpleConfig.jira.issue

      prop_values = {}
      # Get unique labels from release issue and all linked issues
      labels = issue.labels
      issue.linked_issues('deployes').each do |linked_issue|
        labels.concat(linked_issue.labels)
      end
      labels = labels.uniq

      prs = issue.related['pullRequests']

      puts 'Checking for wrong PRs names:'

      prs.each do |pr|
        prname = pr['name'].dup
        unless pr['name'].strip!.nil?
          puts "[#{prname}] - WRONG! Stripped. Bad guy: #{pr['author']['name']}"
        end
      end

      git_style_release = SimpleConfig.jira.issue.tr('-', ' ').downcase.capitalize
      prs.reject! do |pr|
        if pr['name'] !~ /^((#{SimpleConfig.jira.issue})|(#{git_style_release}))/
          LOGGER.warn "[#{pr['name']}] - WRONG NAME! \
                       Expedted /^((#{SimpleConfig.jira.issue})|(#{git_style_release}))/. \
                       Bad guy: #{pr['author']['name']}"
          true
        elsif pr['status'] == 'DECLINED'
          LOGGER.warn "[#{pr['name']}] - DECLINED! Bad guy: #{pr['author']['name']}"
          true
        else
          LOGGER.info "[#{pr['name']}] - OK"
          false
        end
      end

      if prs.empty?
        puts 'No pull requests for this task!'
        exit 1
      end

      puts 'Selected PRs:'
      puts prs.map { |pr| pr['name'] }
      pp prs

      prs.each do |pr|
        repo_name = pr['url'].split('/')[-3]
        unless pr['destination']['branch'].include? 'master'
          puts "WTF? Why is this Pull Request here? o_O (destination: #{pr['destination']['branch']}"
          next
        end
        selected = (repo_dicts[repo_name] & labels.map(&:upcase))
        if selected.empty?
          selected.push repo_dicts[repo_name].first || repo_name.upcase
        end
        selected.each do |proj|
          prop_values[proj] = 'true'
          prop_values["#{proj}_BRANCH"] = pr['source']['branch']
        end
      end

      pp prop_values

      JavaProperties.write prop_values, './.properties'

      exit 0
    end
  end
end
