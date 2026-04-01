import 'package:flutter/material.dart';

class ProfileDetailsWidget extends StatefulWidget {
  final String username;
  final String email;
  final String mobile;
  final VoidCallback onLogout;

  const ProfileDetailsWidget({
    super.key,
    required this.username,
    required this.email,
    required this.mobile,
    required this.onLogout,
  });

  @override
  State<ProfileDetailsWidget> createState() => _ProfileDetailsWidgetState();
}

class _ProfileDetailsWidgetState extends State<ProfileDetailsWidget> {
  bool editUsername = false;
  bool editEmail = false;
  bool editPhone = false;

  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();

    usernameController =
        TextEditingController(text: widget.username);

    emailController =
        TextEditingController(text: widget.email);

    phoneController =
        TextEditingController(text: widget.mobile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),

        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white24,
          child: Icon(
            Icons.person,
            size: 50,
            color: Color(0xFF1A2D75),
          ),
        ),

        const SizedBox(height: 32),

        _EditableRow(
          label: 'Username',
          controller: usernameController,
          isEditing: editUsername,
          onEdit: () {
            setState(() {
              editUsername = !editUsername;
            });
          },
        ),

        _EditableRow(
          label: 'Email',
          controller: emailController,
          isEditing: editEmail,
          onEdit: () {
            setState(() {
              editEmail = !editEmail;
            });
          },
        ),

        _EditableRow(
          label: 'Mobile',
          controller: phoneController,
          isEditing: editPhone,
          onEdit: () {
            setState(() {
              editPhone = !editPhone;
            });
          },
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2D75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: widget.onLogout,
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onEdit;

  const _EditableRow({
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF240A62),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        controller.text,
                        style: const TextStyle(
                          color: Color(0xFF1A1A71),
                          fontSize: 16,
                        ),
                      ),
              ],
            ),
          ),

          GestureDetector(
            onTap: onEdit,
            child: Icon(
              Icons.edit,
              size: 20,
              color: const Color(0xFF291685).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}