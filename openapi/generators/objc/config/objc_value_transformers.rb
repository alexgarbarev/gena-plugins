class ObjcValueTransformers


  def self.type_info_for_property(spec_property)

    if spec_property.type == 'string'

      case spec_property.format
        when 'x-image-name'
          info = ObjcTypeInfoData.new
          info.declaration = 'CCFile *'
          info.schema_value = '"{image-file}"'
          info.import_headers = ['#import "CCFile.h"']
          return info
        when 'x-video-name'
          info = ObjcTypeInfoData.new
          info.declaration = 'CCFile *'
          info.schema_value = '"{video-file}"'
          info.import_headers = ['#import "CCFile.h"']
          return info
        when 'x-audio-name'
          info = ObjcTypeInfoData.new
          info.declaration = 'CCFile *'
          info.schema_value = '"{audio-file}"'
          info.import_headers = ['#import "CCFile.h"']
          return info
        when 'binary'
          info = ObjcTypeInfoData.new
          info.declaration = 'TRCMultipartFile *'
          info.schema_value = nil
          info.import_headers = ['#import <TyphoonRestClient/TRCSerializerMultipart.h>']
          return info
        when 'date'
          info = ObjcTypeInfoData.new
          info.declaration = 'NSDate *'
          info.schema_value = '"{openapi-date}"'
          return info
        when 'date-time'
          info = ObjcTypeInfoData.new
          info.declaration = 'NSDate *'
          info.schema_value = '"{openapi-date-time}"'
          return info
        when 'date-time-clip'
          info = ObjcTypeInfoData.new
          info.declaration = 'NSDate *'
          info.schema_value = '"{openapi-date-time-clip}"'
          return info
        when 'x-time-hh-mm'
          info = ObjcTypeInfoData.new
          info.declaration = 'NSDate *'
          info.schema_value = '"{time-hh-mm}"'
          return info
        when 'hexcolor'
          info = ObjcTypeInfoData.new
          info.declaration = 'UIColor *'
          info.schema_value = '"{hex-color}"'
          info.import_headers = ['#import <UIKit/UIKit.h>']
          return info
        else
          return nil
      end


    end

  end


end
