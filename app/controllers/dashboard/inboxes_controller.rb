# frozen_string_literal: true

module Dashboard
  class InboxesController < DashboardController
    before_action :set_inbox, only: %i[show update update_members add_member remove_member]
    before_action :authorize_inbox, only: %i[show update update_members add_member remove_member]

    def index
      authorize(Inbox)
      @inboxes = current_account.inboxes.includes(:channel, :inbox_users, :inbox_teams, :teams).order(:name)
      respond_to do |format|
        format.html { redirect_to(inboxes_settings_path) }
        format.json { render(json: @inboxes) }
      end
    end

    def show
      @account_users = current_account.account_users.includes(:roles, user: { avatar_attachment: :blob })
      @teams = current_account.teams.order(:name)

      if params[:modal].present? || request.xhr? || request.headers["Sec-Fetch-Dest"] == "empty"
        render(partial: "dashboard/inboxes/collaborators_modal", layout: false, locals: { inbox: @inbox, account_users: @account_users, teams: @teams })
      else
        render(partial: "dashboard/inboxes/collaborators_modal", layout: "dashboard", locals: { inbox: @inbox, account_users: @account_users, teams: @teams })
      end
    end

    def create
      authorize(Inbox)
      Inboxes::InboxCreator.call(
        inbox_type: params[:inbox_type],
        inbox_params: params,
        current_account: current_account
      )

      redirect_back(fallback_location: root_path, notice: t("dashboard.inboxes.created", default: "Inbox Created!"))
    end

    def update
      if @inbox.update(inbox_params)
        redirect_back(fallback_location: inboxes_settings_path, notice: t("dashboard.inboxes.updated", default: "Inbox updated successfully."))
      else
        redirect_back(fallback_location: inboxes_settings_path, alert: @inbox.errors.full_messages.to_sentence)
      end
    end

    def update_members
      if params.key?(:user_ids)
        @inbox.assign_users(params[:user_ids])
      end

      if params.key?(:team_ids)
        @inbox.assign_teams(params[:team_ids])
      end

      if params.key?(:auto_assign)
        auto_assign_val = params[:auto_assign] == "1" || params[:auto_assign] == "true" || params[:auto_assign] == true
        @inbox.update(auto_assign: auto_assign_val)
      end

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: [
            turbo_stream.replace(
              "inbox_card_#{@inbox.id}",
              partial: "dashboard/settings/inbox_card",
              locals: { inbox: @inbox.reload }
            )
          ])
        end
        format.html { redirect_back(fallback_location: inboxes_settings_path, notice: t("dashboard.inboxes.members_updated", default: "Inbox collaborators updated successfully.")) }
      end
    end

    def add_member
      user = current_account.users.find(params[:user_id])
      @inbox.inbox_users.find_or_create_by!(user_id: user.id)

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.replace(
            "inbox_card_#{@inbox.id}",
            partial: "dashboard/settings/inbox_card",
            locals: { inbox: @inbox }
          ))
        end
        format.html { redirect_back(fallback_location: inboxes_settings_path, notice: t("dashboard.inboxes.member_added", default: "Member added to inbox.")) }
      end
    end

    def remove_member
      @inbox.inbox_users.where(user_id: params[:user_id]).destroy_all

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.replace(
            "inbox_card_#{@inbox.id}",
            partial: "dashboard/settings/inbox_card",
            locals: { inbox: @inbox }
          ))
        end
        format.html { redirect_back(fallback_location: inboxes_settings_path, notice: t("dashboard.inboxes.member_removed", default: "Member removed from inbox.")) }
      end
    end

    private

    def set_inbox
      @inbox = current_account.inboxes.find(params[:id])
    end

    def authorize_inbox
      authorize(@inbox)
    end

    def inbox_params
      params.require(:inbox).permit(:name, :auto_assign, :reopen_window_seconds, :csat_survey_enabled, user_ids: [], team_ids: [])
    end
  end
end
