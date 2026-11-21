import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/geo.dart';
import '../../core/validators.dart';
import '../../models/trail.dart';
import '../../services/auth_service.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';

/// 산책로 정보 입력 (신규 등록 / 수정)
class TrailFormScreen extends StatefulWidget {
  const TrailFormScreen({super.key, this.path, this.editTrailId});
  final List<LatLng>? path;
  final String? editTrailId;

  @override
  State<TrailFormScreen> createState() => _TrailFormScreenState();
}

class _TrailFormScreenState extends State<TrailFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _tags = TextEditingController();
  String _category = 'general';
  XFile? _photo;
  Uint8List? _photoBytes;
  Trail? _editing;
  bool _busy = false;
  bool _loading = false;

  bool get _isEdit => widget.editTrailId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadTrail();
  }

  Future<void> _loadTrail() async {
    setState(() => _loading = true);
    final t = await TrailService.instance.watch(widget.editTrailId!).first;
    if (!mounted) return;
    if (t == null || t.ownerId != AuthService.instance.user?.uid) {
      showSnack(context, '수정 권한이 없습니다.');
      context.pop();
      return;
    }
    setState(() {
      _editing = t;
      _title.text = t.title;
      _desc.text = t.description;
      _tags.text = t.tags.map((e) => '#$e').join(' ');
      _category = t.category;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _photo = x;
      _photoBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final input = TrailInput(
      title: _title.text,
      description: _desc.text,
      tags: Validators.parseTags(_tags.text),
      category: _category,
      photo: _photo,
    );
    setState(() => _busy = true);
    try {
      if (_isEdit) {
        await TrailService.instance.update(_editing!, input);
        if (mounted) {
          showSnack(context, '수정되었습니다.');
          context.pop();
        }
      } else {
        final id = await TrailService.instance.create(widget.path!, input);
        if (mounted) {
          showSnack(context, '산책로가 등록되었습니다! 🎉 (+50P)');
          context.go('/map');
          context.push('/trail/$id');
        }
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEdit && (widget.path == null || widget.path!.length < 2)) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(message: '경로 정보가 없습니다. 지도에서 경로를 먼저 등록해주세요.'),
      );
    }
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final dist = _isEdit ? _editing!.distanceM : pathDistanceM(widget.path!);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '산책로 수정' : '산책로 정보 입력')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('총 ${formatDistance(dist)} · 도보 약 ${formatMinutes(walkingMinutes(dist))}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickPhoto,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _photoBytes != null
                    ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                    : (_editing?.photoUrl != null
                        ? Image.network(_editing!.photoUrl!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFF5F6FA),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 40),
                                SizedBox(height: 4),
                                Text('대표 사진 추가'),
                              ],
                            ),
                          )),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            maxLength: 50,
            decoration: const InputDecoration(labelText: '산책로 이름', hintText: '예) 와온 해변'),
            validator: Validators.length('산책로 이름', 1, 50),
          ),
          TextFormField(
            controller: _desc,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: '소개', hintText: '어떤 산책로인지 알려주세요. (풍경, 추천 시간대 등)'),
            validator: Validators.length('소개', 0, 1000),
          ),
          TextFormField(
            controller: _tags,
            decoration: const InputDecoration(labelText: '태그', hintText: '#노을뷰 #반려견 #데이트'),
          ),
          const SizedBox(height: 16),
          const Text('카테고리', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in TrailCategory.labels.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _category == e.key,
                onSelected: (_) => setState(() => _category = e.key),
              ),
          ]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEdit ? '수정 완료' : '산책로 등록'),
          ),
        ]),
      ),
    );
  }
}
