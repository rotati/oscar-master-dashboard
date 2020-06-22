ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      h2 "Usage report in #{1.month.ago.strftime('%B %Y')}"

      table_for :monthly_usage_report do
        MonthlyUsageReport.new.aggregate_data_without_dev.each do |key, value|
          column key.to_s.titleize do
            value
          end
        end
      end
    end
  end
end
