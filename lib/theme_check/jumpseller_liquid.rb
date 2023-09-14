# frozen_string_literal: true

module ThemeCheck
  class JumpsellerLiquidx
    module Templates
      def self.blocks
        @blocks ||= %w[
          layout
          home
          product
          category
          page
          searchresults
          contactpage
          error
          checkout__cart
          checkout__checkout
          checkout__revieworder
          checkout__success
          customer__account
          customer__address
          customer__details
          customer__login
          customer__reset_password
        ].freeze
      end

      def self.templates
        @templates ||= (BLOCKS - %w[layout]).freeze
      end

      def self.checkout_blocks
        @checkout_blocks ||= %w[
          checkout__cart
          checkout__checkout
          checkout__revieworder
          checkout__success
        ].freeze
      end


      def self.customer_blocks
        @customer_blocks ||= %w[
          customer__account
          customer__address
          customer__details
          customer__login
          customer__reset_password
        ].freeze
      end

      def self.block_template_map
        @block_template_map ||= blocks.each_with_object({}) do |code, hash|
          hash[code] = code.sub('checkout__', '').sub('customer__', 'customer_')
        end.freeze
      end

      def self.template_block_map
        @template_block_map ||= block_template_map.invert.freeze
      end
    end

    module Variables
      def self.global_drop_variables
        @global_drop_variables ||= %w[
          store
          theme
          social
          location
          products
          pages
          cross_selling
          order
          cart
          customer
          random
          component
        ].freeze
      end

      def self.other_global_variables
        @other_global_variables ||= %w[
          breadcrumbs
          canonical_url
          categories
          contact
          contact_form
          current_currency
          current_domain
          current_page
          current_url
          customer_account_url
          customer_details_form
          customer_login_url
          customer_registration_url
          favicon
          powered_by
          languages
          login_form
          menu
          meta_description
          multipass_token
          newsletter_form
          options
          page_title
          search
          sorting_order
        ].freeze
      end

      def self.theme_variables
        @theme_variables ||= {
          'content' => %w[layout],
          'index_for_top_components' => Template.templates,
          'index_for_components' => Template.templates,
          'index_for_bottom_components' => Template.templates
        }.freeze
      end

      def self.variable_templates
        @variable_templates ||= {
          'bought_together' => %w[product],
          'category' => %w[category],
          'checkout_form' => Template.checkout_blocks,
          'content' => %w[layout],
          'coupon_form' => Template.checkout_blocks,
          'customer_address_form' => %w[customer__address],
          'customer_reset_password_form' => %w[customer__reset_password checkout__success],
          'error' => %w[error],
          'estimate_form' => Template.checkout_blocks,
          'filters' => %w[category searchresults],
          'index_for_top_components' => Template.templates,
          'index_for_components' => Template.templates,
          'index_for_bottom_components' => Template.templates,
          'page' => %w[page],
          'product' => %w[product],
          'recommended' => %w[product],
          'show_shipping_estimates' => Template.checkout_blocks,
          'template' => Template.blocks
        }.freeze
      end

      def self.template_variables
        @template_variables ||= begin
          stub = Template::blocks.each_with_object({}) { |code, hash| hash[code] = [] }
          variable_templates.each_with_object(stub) do |(variable, blocks), map|
            blocks.each { |block| map[block].push(variable) }
          end
        end
      end
    end
  end
end
