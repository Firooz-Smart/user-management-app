import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_management_supabase/main.dart';
import 'package:mime/mime.dart';

class Avatar extends StatefulWidget {
  const Avatar({
    super.key,
    required this.imageUrl,
    required this.onUpload,
  });

  final String? imageUrl;
  final void Function(String, String) onUpload;

  @override
  _AvatarState createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.imageUrl == null || widget.imageUrl!.isEmpty)
          Container(
            width: 150,
            height: 150,
            color: Colors.grey,
            child: const Center(
              child: Text('No Image'),
            ),
          )
        else
          Image.network(
            widget.imageUrl!,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
        ElevatedButton(
          onPressed: _isLoading ? null : _upload,
          child: const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _upload() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 300, maxHeight: 300);
    if (imageFile != null) {
      setState(() => _isLoading = true);

      try {
        final bytes = await imageFile.readAsBytes();
        String? mimeType = lookupMimeType(imageFile.path);
        final fileExt = (mimeType!.split('/')[1]);
        final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
        final filePath = fileName;

        await supabase.storage.from('avatars').uploadBinary(filePath, bytes,
            fileOptions: FileOptions(contentType: mimeType));

        final imageUrlResponse = await supabase.storage
            .from('avatars')
            .createSignedUrl(filePath, 60 * 60 * 24 * 365 * 50);

        widget.onUpload(imageUrlResponse, fileName);
      } on StorageException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
      } catch (e) {
        print(e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Unexpected error occurred'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
}
