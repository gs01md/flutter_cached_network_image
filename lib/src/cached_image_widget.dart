import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'scaled_file_image.dart';

import 'dart:ui';

import 'dart:ui' as ui;

import 'dart:async';

import 'dart:io';

import 'package:flutter/services.dart';


typedef Widget ImageWidgetBuilder(
    BuildContext context, ImageProvider imageProvider);
typedef Widget PlaceholderWidgetBuilder(BuildContext context, String url);
typedef Widget LoadingErrorWidgetBuilder(
    BuildContext context, String url, Object error);

class CachedNetworkImage extends StatefulWidget {
  /// Option to use cachemanager with other settings
  final BaseCacheManager cacheManager;

  /// The target image that is displayed.
  final String imageUrl;

  /// Optional builder to further customize the display of the image.
  final ImageWidgetBuilder imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final PlaceholderWidgetBuilder placeholder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final LoadingErrorWidgetBuilder errorWidget;

  /// The duration of the fade-in animation for the [placeholder].
  final Duration placeholderFadeInDuration;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [imageUrl].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [imageUrl].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// children); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with children in right-to-left environments, for
  /// children that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip children with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  // Optional headers for the http request of the image url
  final Map<String, String> httpHeaders;

  /// When set to true it will animate from the old image to the new image
  /// if the url changes.
  final bool useOldImageOnUrlChange;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode colorBlendMode;

  /// Target the interpolation quality for image scaling.
  ///
  /// If not given a value, defaults to FilterQuality.low.
  final FilterQuality filterQuality;

  /// 是否是圆形头像
  final bool circleAvatar;

  CachedNetworkImage({
    Key key,
    @required this.imageUrl,
    this.imageBuilder,
    this.placeholder,
    this.errorWidget,
    this.fadeOutDuration: const Duration(milliseconds: 1000),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 500),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment: Alignment.center,
    this.repeat: ImageRepeat.noRepeat,
    this.matchTextDirection: false,
    this.httpHeaders,
    this.cacheManager,
    this.useOldImageOnUrlChange: false,
    this.color,
    this.filterQuality: FilterQuality.low,
    this.colorBlendMode,
    this.placeholderFadeInDuration,
    this.circleAvatar : false,
  })  : assert(imageUrl != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(filterQuality != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  @override
  CachedNetworkImageState createState() {
    return CachedNetworkImageState();
  }
}

class _ImageTransitionHolder {
  final FileInfo image;
  AnimationController animationController;
  final Object error;
  Curve curve;
  final TickerFuture forwardTickerFuture;



  _ImageTransitionHolder({
    this.image,
    @required this.animationController,
    this.error,
    this.curve: Curves.easeIn,
  }) : forwardTickerFuture = animationController.forward();

  dispose() {
    if (animationController != null) {
      animationController.dispose();
      animationController = null;
    }
  }
}

class CachedNetworkImageState extends State<CachedNetworkImage>
    with TickerProviderStateMixin {
  List<_ImageTransitionHolder> _imageHolders = List();
  Key _streamBuilderKey = UniqueKey();

  double imageHeight = 0.0;
  double imageWidth = 0.0;

  Image _imageTemp;

  @override
  Widget build(BuildContext context) {
    return _animatedWidget();
  }

  @override
  void didUpdateWidget(CachedNetworkImage oldWidget) {
    if (oldWidget.imageUrl != widget.imageUrl) {
      _streamBuilderKey = UniqueKey();
      if (!widget.useOldImageOnUrlChange) {
        _disposeImageHolders();
        _imageHolders.clear();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _disposeImageHolders();
    super.dispose();
  }

  _disposeImageHolders() {
    for (var imageHolder in _imageHolders) {
      imageHolder.dispose();
    }
  }

  loadImageFromFile(String url)  {

    if(this.imageHeight != null && this.imageHeight > 0){
      return;
    }

    AssetBundle _bundle = rootBundle;
    ImageStream stream = new FileImage(File.fromUri(Uri.parse(url)),).resolve(ImageConfiguration.empty);
    Completer<ui.Image> completer = new Completer<ui.Image>();
    ImageStreamListener listener;
    listener = new ImageStreamListener(
            (ImageInfo frame, bool synchronousCall) {
          final ui.Image image = frame.image;
          completer.complete(image);
          stream.removeListener(listener);
        });
    stream.addListener(listener);

    completer.future.then((image){

      translate(image.width.toDouble(),image.height.toDouble());

      setState((){

      });

    });
//    return completer.future;
  }

  _addImage({FileInfo image, Object error, Duration duration}) {
    if (_imageHolders.length > 0) {
      var lastHolder = _imageHolders.last;
      lastHolder.forwardTickerFuture.then((_) {
        if (lastHolder.animationController == null) {
          return;
        }
        if (widget.fadeOutDuration != null) {
          lastHolder.animationController.duration = widget.fadeOutDuration;
        } else {
          lastHolder.animationController.duration = Duration(seconds: 1);
        }
        if (widget.fadeOutCurve != null) {
          lastHolder.curve = widget.fadeOutCurve;
        } else {
          lastHolder.curve = Curves.easeOut;
        }
        lastHolder.animationController.reverse().then((_) {
          _imageHolders.remove(lastHolder);
          if (mounted) setState(() {});
          return null;
        });
      });
    }
    _imageHolders.add(
      _ImageTransitionHolder(
        image: image,
        error: error,
        animationController: AnimationController(
          vsync: this,
          duration: duration ??
              (widget.fadeInDuration ?? Duration(milliseconds: 500)),
        ),
      ),
    );
  }

  _animatedWidget() {
    var fromMemory = _cacheManager().getFileFromMemory(widget.imageUrl);

    return StreamBuilder<FileInfo>(
      key: _streamBuilderKey,
      initialData: fromMemory,
      stream: _cacheManager()
          .getFile(widget.imageUrl, headers: widget.httpHeaders)
          // ignore errors if not mounted
          .handleError(() {}, test: (_) => !mounted)
          .where((f) =>
              f?.originalUrl != fromMemory?.originalUrl ||
              f?.validTill != fromMemory?.validTill),
      builder: (BuildContext context, AsyncSnapshot<FileInfo> snapshot) {
        if (snapshot.hasError) {
          // error
          if (_imageHolders.length == 0 || _imageHolders.last.error == null) {
            _addImage(image: null, error: snapshot.error);
          }
        } else {
          var fileInfo = snapshot.data;

          if (fileInfo == null) {
            // placeholder
            if (_imageHolders.length == 0 || _imageHolders.last.image != null) {
              _addImage(
                  image: null,
                  duration: widget.placeholderFadeInDuration ?? Duration.zero);
            }
          } else if (_imageHolders.length == 0 ||
              _imageHolders.last.image?.originalUrl != fileInfo.originalUrl ||
              _imageHolders.last.image?.validTill != fileInfo.validTill) {

            loadImageFromFile(fileInfo.file.path);

            _addImage(
                image: fileInfo,
                duration: _imageHolders.length > 0 ? null : Duration.zero);
          }
        }

        var children = <Widget>[];
        for (var holder in _imageHolders) {
          if (holder.error != null) {
            children.add(_transitionWidget(
                holder: holder, child: _errorWidget(context, holder.error)));
          } else if (holder.image == null) {
            children.add(_transitionWidget(
                holder: holder, child: _placeholder(context)));
          } else {
//            int targetWidth;
//            int targetHeight;
//            if (widget.width != null &&
//                widget.width != double.infinity &&
//                widget.width != double.nan){
//
//              targetWidth = (widget.width * window.devicePixelRatio).round();
//            }
//
//            if (widget.height != null &&
//                widget.height != double.infinity &&
//                widget.height != double.nan){
//
//              targetHeight = (widget.height * window.devicePixelRatio).round();
//            }

            children.add(_transitionWidget(
                holder: holder,
                child: _image(
                  context,
                  ScaledFileImage(holder.image.file,targetWidth: this.imageWidth.toInt(), targetHeight: this.imageHeight.toInt()),
                )));

            debugPrint("\nScaledFileImage : this.imageWidth ${this.imageWidth} ; this.imageHeight ${this.imageHeight}");
          }
        }

        return Stack(
          fit: StackFit.passthrough,
          alignment: widget.alignment,
          children: children.toList(),
        );
      },
    );
  }

  /// 根据实际的图片宽度，设置压缩的图片宽度
  /// imageWidthIn 图片的宽度
  /// imageHeightIn 图片的高度
  void translate(double imageWidthIn , double imageHeightIn){

    this.imageWidth = imageWidthIn;
    this.imageHeight = imageHeightIn;

    if(imageWidthIn != null && imageWidthIn > 0 && imageHeightIn != null && imageHeightIn > 0){

      /// 获取有效宽度
      double width = MediaQuery.of(context).size.width;
      var size = context?.findRenderObject()?.paintBounds?.size;
      if(size!=null){
        width = size.width;
      }
      if(this.widget.width != null && this.widget.width > 0){
        width = this.widget.width;
      }

      /// 根据图片比例获取宽度
      if(imageWidthIn > width*2){
        this.imageWidth = width*2;
        this.imageHeight = this.imageWidth * imageHeightIn/imageWidthIn;
      }
    }

  }

  Widget _transitionWidget({_ImageTransitionHolder holder, Widget child}) {
    return FadeTransition(
      opacity: CurvedAnimation(
          curve: holder.curve, parent: holder.animationController),
      child: child,
    );
  }

  BaseCacheManager _cacheManager() {
    return widget.cacheManager ?? DefaultCacheManager();
  }

  _image(BuildContext context, ImageProvider imageProvider) {
    ImageProvider imageResizeProvider = imageProvider;

//    _cacheManager().emptyCache();

//    double cachedWidth = (widget.width == null || widget.width == 0) ? 10 : widget.width;
//    double cachedHeight = (widget.height == null || widget.height == 0) ? 16 : widget.height;
//    int targetWidth = (cachedWidth * window.devicePixelRatio).round();
//    int targetHeight = (cachedHeight * window.devicePixelRatio).round();
//    if((cachedWidth != null) && (cachedHeight != null)) {
//      imageResizeProvider = ResizeImage.resizeIfNeeded(targetWidth.toInt()*2 , targetHeight.toInt()*2 , imageProvider);
//      print("\n ResizeImage ${DateTime.now()}\n");
//    }

    Widget result = widget.imageBuilder != null
        ? widget.imageBuilder(context, imageResizeProvider)
        : buildImage(imageResizeProvider);

    return widget.circleAvatar ? ClipOval(
      child: result,
    ) : result;
  }

  Image buildImage(ImageProvider imageResizeProvider){

    _imageTemp = Image(
      image:imageResizeProvider,
      fit: widget.fit,
//      width: widget.width,
//      height: widget.height,
      alignment: widget.alignment,
      repeat: widget.repeat,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      matchTextDirection: widget.matchTextDirection,
      filterQuality: widget.filterQuality,
    );

//    print("图片的宽度：${_imageTemp.width} , 图片的高度：${_imageTemp.height} ");

    return _imageTemp;
  }

  _placeholder(BuildContext context) {
    return widget.placeholder != null
        ? widget.placeholder(context, widget.imageUrl)
        : SizedBox(
            width: widget.width,
            height: widget.height,
          );
  }

  _errorWidget(BuildContext context, Object error) {
    return widget.errorWidget != null
        ? widget.errorWidget(context, widget.imageUrl, error)
        : _placeholder(context);
  }
}
