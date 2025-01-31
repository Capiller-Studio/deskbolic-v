# frozen_string_literal: true

module Dashboard
  class WorkspaceController < DashboardController
    def new
      @account   = Account.new
      @accounts  = Account.all
    end
    
    def create
      params[:user_type] == "agent" ? workspace_request : new_workspace
    end
    
    private
    
    def workspace_request
      account = Account.find_by(email: params[:email])
      
      AdminNotificationMailer.workspace_request(account, current_user).deliver_now
      
      redirect_to submitted_path(current_user.id), notice: "Request Sent"
    end
    
    def new_workspace
      account = Account.new
      account.update(
        name: params[:account][:name],
        email: current_user.email,
        data: { "company-name" => params[:company_name], "workspace-size" => params[:workspace_size] }
      )
      account.users << current_user
      session[:current_account_id] = account.id
      redirect_to submitted_path(current_user.id), notice: "New WorkSpace Created Successfully"
    end
    
    def submitted; end

    def email_invitation
    end
  end
end