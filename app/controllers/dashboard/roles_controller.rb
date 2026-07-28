# frozen_string_literal: true

module Dashboard
  class RolesController < DashboardController
    before_action :set_role, only: [:edit, :update, :destroy]

    def index
      authorize ::Access::Role
      roles = current_account.roles.includes(:account_user_roles)
      @system_roles = roles.system_roles.order(:name)
      @custom_roles = roles.custom_roles.order(:name)
      @team_members_count = current_account.account_users.count
      @permissions_count = (@system_roles.to_a + @custom_roles.to_a).sum do |role|
        role.permissions.to_h.sum do |_resource, actions|
          actions.to_h.count do |_action, enabled|
            enabled.present? && enabled != false && enabled != "false"
          end
        end
      end
    end

    def new
      authorize ::Access::Role
      @role = ::Access::Role.new
    end

    def edit
      authorize @role
    end

    def create
      authorize ::Access::Role
      @role = current_account.roles.build(role_params)

      if @role.save
        redirect_to roles_path, notice: I18n.t("dashboard.roles.create.success", default: "Role created successfully.")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize @role
      if @role.update(role_params)
        redirect_to roles_path, notice: I18n.t("dashboard.roles.update.success", default: "Role updated successfully.")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @role
      
      if @role.system_provided?
        redirect_to roles_path, alert: I18n.t("dashboard.roles.destroy.system_role", default: "System roles cannot be deleted.")
      elsif @role.destroy
        redirect_to roles_path, notice: I18n.t("dashboard.roles.destroy.success", default: "Role deleted successfully.")
      else
        redirect_to roles_path, alert: I18n.t("dashboard.roles.destroy.error", default: "Failed to delete role.")
      end
    end

    private

    def set_role
      @role = current_account.roles.find(params[:id])
    end

    def role_params
      rp = params.require(:access_role).permit(:name, :permissions).to_h
      
      if rp["permissions"].is_a?(String) && rp["permissions"].present?
        begin
          rp["permissions"] = JSON.parse(rp["permissions"])
        rescue JSON::ParserError
          rp["permissions"] = {}
        end
      else
        rp["permissions"] = {}
      end
      
      rp
    end
  end
end
