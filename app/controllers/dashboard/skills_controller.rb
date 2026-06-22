# frozen_string_literal: true

module Dashboard
  class SkillsController < DashboardController
    before_action :set_skill, only: [:edit, :update, :destroy]

    def index
      authorize(Skill)

      @skills = current_account.skills.ordered
      @skills = @skills.by_type(params[:type]) if params[:type].present?
    end

    def new
      @skill = current_account.skills.new
      authorize(@skill)
    end

    def create
      @skill = current_account.skills.new(skill_params)
      authorize(@skill)

      if @skill.save
        redirect_to(skills_path, notice: t(".created"))
      else
        render(:new, status: :unprocessable_entity)
      end
    end

    def edit
      authorize(@skill)
    end

    def update
      authorize(@skill)

      if @skill.update(skill_params)
        redirect_to(skills_path, notice: t(".updated"))
      else
        @skills = current_account.skills.ordered
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      authorize(@skill)
      @skill.destroy!

      respond_to do |format|
        format.turbo_stream { render(turbo_stream: turbo_stream.remove("skill_#{@skill.id}")) }
        format.html { redirect_to(skills_path, notice: t(".destroyed")) }
      end
    end

    private

    def set_skill
      @skill = current_account.skills.find(params[:id])
    end

    def skill_params
      params.require(:skill).permit(:name, :skill_type, :description, :status)
    end
  end
end
