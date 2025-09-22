class BaseDecorator < Draper::Decorator
  delegate_all

  def img_attachments_count
    images.attached? ? images.count : 0
  end
end