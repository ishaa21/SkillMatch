import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../core/theme/app_theme.dart';

class AddSkillModal extends StatefulWidget {
  final Function(String skillName, String proficiency) onSkillAdded;

  const AddSkillModal({super.key, required this.onSkillAdded});

  @override
  State<AddSkillModal> createState() => _AddSkillModalState();
}

class _AddSkillModalState extends State<AddSkillModal> {
  String _selectedProficiency = 'Intermediate';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Comprehensive skill list with icons
  final List<Map<String, dynamic>> allSkills = [
    // Programming Languages
    {'name': 'Flutter', 'icon': Icons.phone_android, 'color': Colors.blue},
    {'name': 'React', 'icon': FontAwesomeIcons.react, 'color': Colors.cyan},
    {'name': 'Python', 'icon': FontAwesomeIcons.python, 'color': Colors.yellow},
    {'name': 'JavaScript', 'icon': FontAwesomeIcons.js, 'color': Colors.amber},
    {'name': 'Java', 'icon': FontAwesomeIcons.java, 'color': Colors.red},
    {'name': 'Node.js', 'icon': FontAwesomeIcons.node, 'color': Colors.green},
    {'name': 'TypeScript', 'icon': Icons.code, 'color': Colors.blue},
    {'name': 'Dart', 'icon': Icons.flutter_dash, 'color': Colors.blue},
    {'name': 'Swift', 'icon': FontAwesomeIcons.swift, 'color': Colors.orange},
    {'name': 'Kotlin', 'icon': Icons.android, 'color': Colors.purple},
    {'name': 'C++', 'icon': Icons.code, 'color': Colors.blue},
    {'name': 'C#', 'icon': Icons.code, 'color': Colors.purple},
    {'name': 'Go', 'icon': Icons.code, 'color': Colors.cyan},
    {'name': 'Rust', 'icon': Icons.code, 'color': Colors.orange},
    {'name': 'PHP', 'icon': FontAwesomeIcons.php, 'color': Colors.indigo},
    {'name': 'Ruby', 'icon': Icons.diamond, 'color': Colors.red},
    
    // Frameworks & Libraries
    {'name': 'Angular', 'icon': FontAwesomeIcons.angular, 'color': Colors.red},
    {'name': 'Vue.js', 'icon': FontAwesomeIcons.vuejs, 'color': Colors.green},
    {'name': 'Django', 'icon': Icons.web, 'color': Colors.green},
    {'name': 'Spring Boot', 'icon': Icons.security, 'color': Colors.green},
    {'name': 'Express.js', 'icon': Icons.backup, 'color': Colors.grey},
    {'name': 'Laravel', 'icon': FontAwesomeIcons.laravel, 'color': Colors.red},
    {'name': 'Next.js', 'icon': Icons.next_plan, 'color': Colors.black},
    
    // Design & UI/UX
    {'name': 'Figma', 'icon': FontAwesomeIcons.figma, 'color': Colors.purple},
    {'name': 'Adobe XD', 'icon': Icons.design_services, 'color': Colors.pink},
    {'name': 'Photoshop', 'icon': Icons.photo, 'color': Colors.blue},
    {'name': 'Illustrator', 'icon': Icons.brush, 'color': Colors.orange},
    {'name': 'UI/UX Design', 'icon': Icons.palette, 'color': Colors.purple},
    {'name': 'Canva', 'icon': Icons.auto_awesome, 'color': Colors.cyan},
    
    // Data & Analytics
    {'name': 'SQL', 'icon': FontAwesomeIcons.database, 'color': Colors.blue},
    {'name': 'MongoDB', 'icon': Icons.storage, 'color': Colors.green},
    {'name': 'PostgreSQL', 'icon': FontAwesomeIcons.database, 'color': Colors.blue},
    {'name': 'Firebase', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'name': 'MySQL', 'icon': FontAwesomeIcons.database, 'color': Colors.blue},
    {'name': 'Redis', 'icon': Icons.memory, 'color': Colors.red},
    {'name': 'Excel', 'icon': FontAwesomeIcons.fileExcel, 'color': Colors.green},
    {'name': 'Tableau', 'icon': Icons.analytics, 'color': Colors.blue},
    {'name': 'Power BI', 'icon': Icons.bar_chart, 'color': Colors.yellow},
    
    // DevOps & Cloud
    {'name': 'Docker', 'icon': FontAwesomeIcons.docker, 'color': Colors.blue},
    {'name': 'Kubernetes', 'icon': Icons.cloud, 'color': Colors.blue},
    {'name': 'AWS', 'icon': FontAwesomeIcons.aws, 'color': Colors.orange},
    {'name': 'Azure', 'icon': FontAwesomeIcons.microsoft, 'color': Colors.blue},
    {'name': 'Google Cloud', 'icon': FontAwesomeIcons.google, 'color': Colors.blue},
    {'name': 'Git', 'icon': FontAwesomeIcons.git, 'color': Colors.orange},
    {'name': 'GitHub', 'icon': FontAwesomeIcons.github, 'color': Colors.black},
    {'name': 'GitLab', 'icon': FontAwesomeIcons.gitlab, 'color': Colors.orange},
    {'name': 'Jenkins', 'icon': Icons.build, 'color': Colors.red},
    {'name': 'CI/CD', 'icon': Icons.sync, 'color': Colors.blue},
    
    // AI & Machine Learning
    {'name': 'TensorFlow', 'icon': Icons.psychology, 'color': Colors.orange},
    {'name': 'PyTorch', 'icon': Icons.memory, 'color': Colors.red},
    {'name': 'Machine Learning', 'icon': Icons.smart_toy, 'color': Colors.purple},
    {'name': 'Deep Learning', 'icon': Icons.psychology_alt, 'color': Colors.deepPurple},
    {'name': 'NLP', 'icon': Icons.chat, 'color': Colors.green},
    {'name': 'Computer Vision', 'icon': Icons.visibility, 'color': Colors.blue},
    
    // Testing & QA
    {'name': 'Jest', 'icon': Icons.check_circle, 'color': Colors.red},
    {'name': 'Selenium', 'icon': Icons.bug_report, 'color': Colors.green},
    {'name': 'Cypress', 'icon': Icons.verified, 'color': Colors.green},
    {'name': 'Unit Testing', 'icon': Icons.check, 'color': Colors.blue},
    
    // Other Technical Skills
    {'name': 'RESTful API', 'icon': Icons.api, 'color': Colors.blue},
    {'name': 'GraphQL', 'icon': Icons.graphic_eq, 'color': Colors.pink},
    {'name': 'Microservices', 'icon': Icons.apps, 'color': Colors.blue},
    {'name': 'Agile', 'icon': Icons.speed, 'color': Colors.green},
    {'name': 'Scrum', 'icon': Icons.groups, 'color': Colors.orange},
    {'name': 'Linux', 'icon': FontAwesomeIcons.linux, 'color': Colors.black},
    
    // Soft Skills
    {'name': 'Communication', 'icon': Icons.chat_bubble, 'color': Colors.blue},
    {'name': 'Leadership', 'icon': Icons.face, 'color': Colors.purple},
    {'name': 'Problem Solving', 'icon': Icons.lightbulb, 'color': Colors.yellow},
    {'name': 'Teamwork', 'icon': Icons.group, 'color': Colors.green},
    {'name': 'Time Management', 'icon': Icons.schedule, 'color': Colors.orange},
    {'name': 'Project Management', 'icon': Icons.assignment, 'color': Colors.blue},
  ];

  List<Map<String, dynamic>> get filteredSkills {
    if (_searchQuery.isEmpty) return allSkills;
    return allSkills
        .where((skill) => skill['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Skills',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search skills...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Proficiency selector
                Row(
                  children: [
                    const Text('Proficiency Level:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                              .map((level) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(level),
                                      selected: _selectedProficiency == level,
                                      selectedColor: AppColors.primary,
                                      labelStyle: TextStyle(
                                        color: _selectedProficiency == level
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedProficiency = level);
                                        }
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Skills grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredSkills.length,
              itemBuilder: (context, index) {
                final skill = filteredSkills[index];
                return _buildSkillCard(skill);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    return GestureDetector(
      onTap: () {
        widget.onSkillAdded(skill['name'], _selectedProficiency);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (skill['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: skill['icon'] is IconData
                  ? Icon(
                      skill['icon'] as IconData,
                      color: skill['color'],
                      size: 28,
                    )
                  : FaIcon(
                      skill['icon'] as IconData,
                      color: skill['color'],
                      size: 28,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              skill['name'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
