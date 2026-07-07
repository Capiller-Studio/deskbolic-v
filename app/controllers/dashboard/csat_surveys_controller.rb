# frozen_string_literal: true

module Dashboard
  class CsatSurveysController < DashboardController
    before_action :set_csat_survey, only: %i[edit update destroy]

    def index
      authorize ::Csat::Survey
      @csat_surveys = Current.account.csat_surveys.includes(:translations, :email_template)
    end

    def new
      authorize ::Csat::Survey
      @csat_survey = ::Csat::Survey.new
    end

    def create
      authorize ::Csat::Survey
      
      @csat_survey = ::Csat::Surveys::CreateService.call(
        Current.account,
        csat_survey_params
      )

      respond_to do |format|
        format.html { redirect_to csat_surveys_path, notice: "CSAT Survey created successfully." }
        format.json { render json: { success: true, redirect_url: csat_surveys_path } }
      end
    rescue StandardError => e
      respond_to do |format|
        format.html do
          @csat_survey ||= ::Csat::Survey.new(csat_survey_params)
          flash.now[:alert] = e.message
          render :new, status: :unprocessable_entity
        end
        format.json { render json: { success: false, errors: [e.message] }, status: :unprocessable_entity }
      end
    end

    def edit
      authorize @csat_survey
      @locale = params[:survey_locale] || I18n.locale.to_s
    end

    def update
      authorize @csat_survey
      locale = params[:survey_locale] || I18n.locale.to_s

      I18n.with_locale(locale) do
        if @csat_survey.update(csat_survey_params)
          respond_to do |format|
            format.html { redirect_to csat_surveys_path, notice: "CSAT Survey updated successfully." }
            format.json { render json: { success: true, redirect_url: csat_surveys_path } }
          end
        else
          respond_to do |format|
            format.html do
              flash.now[:alert] = @csat_survey.errors.full_messages.join(", ")
              render :edit, status: :unprocessable_entity
            end
            format.json { render json: { success: false, errors: @csat_survey.errors.full_messages }, status: :unprocessable_entity }
          end
        end
      end
    end

    def destroy
      authorize @csat_survey

      ::Csat::Surveys::DestroyService.call(@csat_survey)

      respond_to do |format|
        format.html { redirect_to csat_surveys_path, notice: "CSAT Survey deleted." }
        format.json { render json: { success: true, message: "CSAT Survey deleted." } }
      end
    rescue StandardError => e
      respond_to do |format|
        format.html { redirect_to csat_surveys_path, alert: e.message }
        format.json { render json: { success: false, errors: [e.message] }, status: :unprocessable_entity }
      end
    end

    private

    def set_csat_survey
      @csat_survey = Current.account.csat_surveys.find(params[:id])
    end

    def csat_survey_params
      params.require(:csat_survey).permit(
        :name, :prompt, :portal_title, :portal_subtitle, :portal_feedback_label, :email_template_id,
        translations_attributes: [
          :id, :locale, :prompt, :portal_title, :portal_subtitle, :portal_feedback_label, :_destroy
        ]
      )
    end
  end
end
