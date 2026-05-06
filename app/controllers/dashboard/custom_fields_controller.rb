# frozen_string_literal: true

module Dashboard
  class CustomFieldsController < DashboardController
    before_action :set_custom_field, only: %i[edit update destroy]

    def index
      @custom_fields = current_account.custom_fields.includes(:translations).order(created_at: :desc)
    end

    def new
      @custom_field = current_account.custom_fields.new
    end

    def create
      # Check account limits here before creation
      # For example: authorize! :create, CustomField

      @custom_field = current_account.custom_fields.new(custom_field_params)

      if @custom_field.save
        handle_translations
        redirect_to custom_fields_path, notice: "Custom Field was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @custom_field.update(custom_field_params)
        handle_translations
        redirect_to custom_fields_path, notice: "Custom Field was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @custom_field.destroy
      redirect_to custom_fields_path, notice: "Custom Field was successfully deleted."
    end

    private

    def set_custom_field
      @custom_field = current_account.custom_fields.find(params[:id])
    end

    def custom_field_params
      permitted = params.require(:custom_field).permit(
        :key, :entity_type, :field_type, :required, 
        :searchable, :filterable, :hidden, :is_readonly,
        validations: [:min_length, :max_length, :pattern, allowed_values: []]
      )

      # Process translations_attributes if present to handle the options JSON array
      if params[:custom_field][:translations_attributes].present?
        translations = params[:custom_field][:translations_attributes].values.map do |trans|
          options_array = []
          if trans["options"].is_a?(Hash) || trans["options"].is_a?(ActionController::Parameters)
            options_array = trans["options"].values.reject { |opt| opt["value"].blank? && opt["label"].blank? }
          elsif trans["options"].is_a?(Array)
            options_array = trans["options"].reject { |opt| opt["value"].blank? && opt["label"].blank? }
          end

          {
            id: trans["id"],
            locale: trans["locale"],
            label: trans["label"],
            placeholder: trans["placeholder"],
            options: options_array
          }.compact
        end
        permitted[:translations_attributes] = translations
      end

      # Strip empty validations
      if permitted[:validations].present?
        permitted[:validations] = permitted[:validations].to_h.reject { |_, v| v.blank? }
      end

      permitted
    end

    def handle_translations
      # Obsolete: accepts_nested_attributes_for :translations handles persistence automatically
    end
  end
end
