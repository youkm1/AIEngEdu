class AddAudioFieldsToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :has_user_audio, :boolean, default: false
    add_column :messages, :audio_duration, :float
    add_column :messages, :audio_format, :string
    
    add_index :messages, :has_user_audio
  end
end
