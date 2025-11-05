class BaseDecorator < Draper::Decorator
  delegate_all

  def img_attachments_count
    object.images.count
  end
end
