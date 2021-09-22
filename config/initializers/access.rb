# frozen_string_literal: true

# Add rights to Ekylibre
Ekylibre::Access.load_file(Planning::Engine.root.join('config', 'rights.yml'))
