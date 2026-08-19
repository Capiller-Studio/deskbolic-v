# frozen_string_literal: true

module Dashboard
  class SkillsController < DashboardController
    before_action :set_skill, only: [ :edit, :update, :destroy ]

    def index
      authorize(Skill)

      @skills = current_account.skills.ordered
      @skill_counts = {
        all: @skills.count,
        general: @skills.where(skill_type: :general).count,
        language: @skills.where(skill_type: :language).count,
        product: @skills.where(skill_type: :product).count,
        technical: @skills.where(skill_type: :technical).count
      }

      @selected_type = %w[general language product technical].include?(params[:type]) ? params[:type] : "all"

      @skill_tabs = [
        { key: :all, label: t(".tab_all", default: "All"), path: skills_path },
        { key: :general, label: t(".tab_general", default: "General"), path: skills_path(type: :general) },
        { key: :language, label: t(".tab_language", default: "Language"), path: skills_path(type: :language) },
        { key: :product, label: t(".tab_product", default: "Product"), path: skills_path(type: :product) },
        { key: :technical, label: t(".tab_technical", default: "Technical"), path: skills_path(type: :technical) }
      ]

      @skills = @skills.by_type(@selected_type) if @selected_type != "all"
    end

    def new
      @skill = current_account.skills.new
      authorize(@skill)
    end

    def edit
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
      params.expect(skill: [ :name, :skill_type, :description, :status ])
    end
  end
end
