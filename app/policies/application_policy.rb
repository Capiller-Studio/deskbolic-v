# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :account, :record, :account_user

  def initialize(user, record)
    @user = user
    @record = record
    @account = Current.account
    @account_user = @account&.account_users&.find_by(user: @user)
  end

  protected

  def can?(permission_string)
    return false unless account_user
    account_user.can?(permission_string, resource: record)
  end

  def owner?
    account_user&.owner?
  end

  def account_feature_enabled?(feature)
    account&.feature_enabled?(feature)
  end

  def account_within_limit?(resource, strict: true)
    return true if account.nil?
    !account.limit_reached?(resource, strict: strict)
  end


  # Unified Access Check
  def authorized?(permission, feature: nil, limit: nil)
    # 1. User Role Check
    return false unless can?(permission)

    # 2. Account Feature Check
    if feature && !account_feature_enabled?(feature)
      @authorization_failure_reason = :feature_not_enabled
      @authorization_failure_feature = feature
      return false
    end

    # 3. Usage Limit Check
    if limit
      # Monthly resources and customers allow "Soft Blocks"
      is_soft = limit.to_s.include?("monthly") || limit.to_s == "customers"
      unless account_within_limit?(limit, strict: !is_soft)
        @authorization_failure_reason = :limit_reached
        @authorization_failure_limit = limit
        return false
      end
    end

    true
  end

  public

  attr_reader :authorization_failure_reason, :authorization_failure_feature, :authorization_failure_limit

  # --- Pundit Action Methods (must be public) ---

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :account, :scope

    def initialize(user, scope)
      @user = user
      @account = Current.account
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
