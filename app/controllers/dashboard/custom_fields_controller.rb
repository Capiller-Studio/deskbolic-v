# frozen_string_literal: true

module Dashboard
  class CustomFieldsController < DashboardController
    before_action :set_custom_field, only: %i[edit update destroy]

    def index
      authorize(CustomField)

      current_account.with_shard do
        fields_scope = current_account.custom_fields.includes(:translations)
        entity_counts = fields_scope.group(:entity_type).count
        @field_counts = {
          all: fields_scope.count,
          customer: entity_counts.fetch("customer", 0),
          conversation: entity_counts.fetch("conversation", 0)
        }
        @pagy, @custom_fields = pagy(
          fields_scope.order(created_at: :desc),
          page_param: :page, limit: 20
        )
      end
    end

    def new
      authorize(CustomField)
      @custom_field = current_account.custom_fields.new
    end

    def edit
      authorize(@custom_field)
    end
    def create
      authorize(CustomField)

      current_account.with_shard do
        @custom_field = current_account.custom_fields.new(custom_field_params)

        if @custom_field.save
          redirect_to(custom_fields_path, notice: "Custom Field was successfully created.")
        else
          render(:new, status: :unprocessable_entity)
        end
      end
    end


    def update
      authorize(@custom_field)

      current_account.with_shard do
        if @custom_field.update(custom_field_params.except(:field_type))
          redirect_to(custom_fields_path, notice: "Custom Field was successfully updated.")
        else
          render(:edit, status: :unprocessable_entity)
        end
      end
    end

    def destroy
      authorize(@custom_field)

      current_account.with_shard do
        @custom_field.destroy
        redirect_to(custom_fields_path, notice: "Custom Field was successfully deleted.")
      end
    rescue ActiveRecord::InvalidForeignKey
      redirect_to(custom_fields_path, alert: "Cannot delete this field. It's in use.")
    end

    private

    def set_custom_field
      current_account.with_shard do
        @custom_field = current_account.custom_fields.find(params[:id])
      end
    end

    def custom_field_params
      permitted = params.expect(
        custom_field: [ :key, :entity_type, :field_type, :required, :mapped_to,
        :searchable, :filterable, :hidden, :is_readonly, :default_value,
        validations: [ :min_length, :max_length, :pattern, :min_value, :max_value, allowed_values: [] ] ]
      ).to_h

      if params[:custom_field][:translations_attributes].present?
        translations = []
        params[:custom_field][:translations_attributes].each_value do |trans|
          options_array = []
          if trans["options"].is_a?(Hash) || trans["options"].is_a?(ActionController::Parameters)
            options_array = trans["options"].values.reject { |opt| opt["value"].blank? && opt["label"].blank? }
          elsif trans["options"].is_a?(Array)
            options_array = trans["options"].reject { |opt| opt["value"].blank? && opt["label"].blank? }
          end

          translations << {
            "id" => trans["id"],
            "locale" => trans["locale"],
            "label" => trans["label"],
            "placeholder" => trans["placeholder"],
            "description" => trans["description"],
            "_destroy" => trans["_destroy"],
            "options" => options_array.map { |o| { "value" => o["value"], "label" => o["label"] } }
          }.compact
        end
        permitted["translations_attributes"] = translations
      end

      if permitted["validations"].present?
        permitted["validations"] = permitted["validations"].compact_blank
      end

      permitted
    end
  end
end
